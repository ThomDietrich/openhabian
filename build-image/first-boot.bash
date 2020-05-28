#!/bin/bash

CONFIGFILE=/etc/openhabian.conf

# apt/dpkg commands will not try interactive dialogs
export DEBIAN_FRONTEND=noninteractive

# Log everything to file
exec &> >(tee -a "/boot/first-boot.log")

timestamp() { date +"%F_%T_%Z"; }

fail_inprogress() {
  rm -f /opt/openHABian-install-inprogress
  touch /opt/openHABian-install-failed
  echo -e "$(timestamp) [openHABian] Initial setup exiting with an error!\\n\\n"
  exit 1
}

echo "$(timestamp) [openHABian] Starting the openHABian initial setup."
rm -f /opt/openHABian-install-failed
touch /opt/openHABian-install-inprogress

echo -n "$(timestamp) [openHABian] Storing configuration... "
cp /boot/openhabian.conf /etc/openhabian.conf
sed -i 's/\r$//' /etc/openhabian.conf

# shellcheck disable=SC1090
source "$CONFIGFILE"
echo "OK"

if [ -n "$DEBUGMAX" ]; then
  echo "$(timestamp) [openHABian] Enable maximum debugging output (DEBUGMAX=${DEBUGMAX})."
  set -x
fi

echo -n "$(timestamp) [openHABian] Starting webserver with installation log... "
if hash python3 2>/dev/null; then
  bash /boot/webif.bash start
  sleep 5
  webifisrunning=$(ps -ef | pgrep python3)
  if [ -z "$webifisrunning" ]; then
    echo "FAILED"
  else
    echo "OK"
  fi
else
  echo "Python not found, SKIPPED"
fi

userdef="openhabian"
if is_pi; then
  userdef="pi"
fi

echo -n "$(timestamp) [openHABian] Changing default username and password... "
# shellcheck disable=SC2154
if [ -z "${username+x}" ] || ! id $userdef &>/dev/null || id "$username" &>/dev/null; then
  echo "SKIPPED"
else
  usermod -l "$username" "$userdef"
  usermod -m -d "/home/$username" "$username"
  groupmod -n "$username" "$userdef"
  chpasswd <<< "$username:${userpw:-$username}"
  echo "OK"
fi

# While setup: show log to logged in user, will be overwritten by openhabian-setup.sh
echo "watch cat /boot/first-boot.log" > "$HOME/.bash_profile"

# shellcheck disable=SC2154
if [ -z "${wifi_ssid}" ]; then
  echo "$(timestamp) [openHABian] Setting up Ethernet connection... OK"
elif grep -q "openHABian" /etc/wpa_supplicant/wpa_supplicant.conf && ! grep -q "^[[:space:]]*dtoverlay=disable-wifi" /boot/config.txt; then
  echo -n "$(timestamp) [openHABian] Setting up Wi-Fi connection... "
  if iwlist wlan0 scanning 2>&1 | grep -q "Interface doesn't support scanning"; then
    # wifi might be blocked
    rfkill unblock wifi
    ifconfig wlan0 up
    if iwlist wlan0 scanning 2>&1 | grep -q "Interface doesn't support scanning"; then
      echo "FAILED"
      echo "$(timestamp) [openHABian] I was not able to turn on the wifi - here is some more information:"
      rfkill list all
      ifconfig
      fail_inprogress
    fi
  fi
  echo "OK"
else
  echo -n "$(timestamp) [openHABian] Setting up Wi-Fi connection... "

  # check the user input for the country code
  # check: from the start of line, the uppercased input must be followed by a whitespace
  if [ -z "$wifi_country" ]; then
    wifi_country="US"
  elif grep -q "^${wifi_country^^}\\s" /usr/share/zoneinfo/zone.tab; then
    wifi_country=${wifi_country^^}
  else
    echo "${wifi_country} is not a valid country code found in /usr/share/zoneinfo/zone.tab"
    echo "Defaulting to US"
    wifi_country="US"
  fi

  echo -e "# config generated by openHABian first boot setup" > /etc/wpa_supplicant/wpa_supplicant.conf
  echo -e "country=$wifi_country\\nctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\\nupdate_config=1" >> /etc/wpa_supplicant/wpa_supplicant.conf
  # shellcheck disable=SC2154
  if ! WNET=$(wpa_passphrase "${wifi_ssid}" "${wifi_psk}"); then
    echo FAILED
    echo "$WNET"
  else
    echo "# network config created by wpa_passphrase to ensure correct handling of special characters" >> /etc/wpa_supplicant/wpa_supplicant.conf
    echo -e "${WNET//\}/\\tkey_mgmt=WPA-PSK\\n\}}" >> /etc/wpa_supplicant/wpa_supplicant.conf

    sed -i "s/REGDOMAIN=.*/REGDOMAIN=${wifi_country}/g" /etc/default/crda

    if is_pi; then
      echo "OK, rebooting... "
      reboot
    else
      wpa_cli reconfigure &>/dev/null
      echo "OK"
    fi
  fi
fi

echo -n "$(timestamp) [openHABian] Ensuring network connectivity... "
if tryUntil "ping -c1 9.9.9.9 >/dev/null || wget -S -t 3 --waitretry=4 http://www.msftncsi.com/ncsi.txt 2>&1 | grep -q 'Microsoft NCSI'" 10 1; then
    echo "FAILED"
    if grep -q "openHABian" /etc/wpa_supplicant/wpa_supplicant.conf && iwconfig 2>&1 | grep -q "ESSID:off"; then
      echo "$(timestamp) [openHABian] I was not able to connect to the configured Wi-Fi. Please check your signal quality. Reachable Wi-Fi networks are:"
      iwlist wlan0 scanning | grep "ESSID" | sed 's/^\s*ESSID:/\t- /g'
      echo "$(timestamp) [openHABian] Please try again with your correct SSID and password. The following Wi-Fi configuration was used:"
      cat /etc/wpa_supplicant/wpa_supplicant.conf
      rm -f /etc/wpa_supplicant/wpa_supplicant.conf
    else
      echo "$(timestamp) [openHABian] The public internet is not reachable. Please check your network."
    fi
    fail_inprogress
  fi
echo "OK"

echo -n "$(timestamp) [openHABian] Waiting for dpkg/apt to get ready... "
until apt-get update &>/dev/null; do sleep 1; done
sleep 10  # Related to: https://github.com/openhab/openhabian/issues/441#issuecomment-448583415
echo "OK"

echo -n "$(timestamp) [openHABian] Updating repositories and upgrading installed packages... "
apt-get --yes --fix-broken install &>/dev/null
if apt-get --yes upgrade &>/dev/null; then echo "OK"; else echo "FAILED"; fail_inprogress; fi

if hash python3 2>/dev/null; then bash /boot/webif.bash reinsure_running; fi

echo -n "$(timestamp) [openHABian] Installing git package... "
if apt-get -y install git &>/dev/null; then echo "OK"; else echo "FAILED"; fail_inprogress; fi

if [ -d /opt/openhabian/ ]; then cd /opt && rm -rf /opt/openhabian/; fi
# shellcheck disable=SC2154
echo -n "$(timestamp) [openHABian] Cloning myself from ${repositoryurl}, ${clonebranch} branch... "
if git clone -q -b "$clonebranch" "$repositoryurl" /opt/openhabian; then echo "OK"; else echo "FAILED"; fail_inprogress; fi
ln -sfn /opt/openhabian/openhabian-setup.sh /usr/local/bin/openhabian-config

# shellcheck disable=SC2154
echo "$(timestamp) [openHABian] Executing openhabian-setup.sh ${mode}... "
if (/bin/bash /opt/openhabian/openhabian-setup.sh "$mode"); then
  rm -f /opt/openHABian-install-inprogress
  touch /opt/openHABian-install-successful
else
  fail_inprogress
fi
echo "$(timestamp) [openHABian] Execution of 'openhabian-setup.sh unattended' completed."

echo -n "$(timestamp) [openHABian] Waiting for openHAB to become ready on $HOSTNAME ..."

# this took ~130 seconds on a RPi2
if tryUntil "wget -S --spider -t 3 --waitretry=4 http://${HOSTNAME}:8080/start/index 2>&1 | grep -q 'HTTP/1.1 200 OK'" 20 10; then echo "failed."; exit 1; fi
echo " OK"

echo "$(timestamp) [openHABian] Visit the openHAB dashboard now: http://${HOSTNAME:-openhab}:8080"
echo "$(timestamp) [openHABian] To gain access to a console, simply reconnect."
echo "$(timestamp) [openHABian] First time setup successfully finished."
sleep 12
if hash python3 2>/dev/null; then bash /boot/webif.bash inst_done; fi
sleep 12
if hash python3 2>/dev/null; then bash /boot/webif.bash cleanup; fi

if [ -z "$SILENT" ]; then
  echo -e "\n\e[36mMemory usage:"
  free -m && ps -auxq "$(cat /var/lib/openhab2/tmp/karaf.pid)" |awk '/openhab/ {print "size/res="$5"/"$6" KB"}'
fi

# vim: filetype=sh
