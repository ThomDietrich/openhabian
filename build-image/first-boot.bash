#!/bin/bash

# apt/dpkg commands will not try interactive dialogs
export DEBIAN_FRONTEND=noninteractive

source "init.bash"
source "$CONFIGFILE"

# Log everything to file
exec &> >(tee -a "/boot/first-boot.log")

timestamp() { date +"%F_%T_%Z"; }

fail_inprogress() {
  rm -f /opt/openHABian-install-inprogress
  touch /opt/openHABian-install-failed
  echo -e "$(timestamp) [openHABian] Initial setup exiting with an error!\\n\\n"
  exit 1
}

if [ -n "DEBUGMAX" ]; then
  set -x
fi

echo "$(timestamp) [openHABian] Starting the openHABian initial setup."
rm -f /opt/openHABian-install-failed
touch /opt/openHABian-install-inprogress

echo -n "$(timestamp) [openHABian] Storing configuration... "
cp /boot/openhabian.conf /etc/openhabian.conf
sed -i 's/\r$//' /etc/openhabian.conf
# shellcheck source=openhabian.pine64.conf
source /etc/openhabian.conf
echo "OK"

echo -n "$(timestamp) [openHABian] Starting webserver with installation log... "
if hash python3 2>/dev/null; then
  bash /boot/webif.bash start
  sleep 5
  webifisrunning=$(ps -ef | pgrep python3)
  if [ -z $webifisrunning ]; then
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
if [ -z ${username+x} ] || ! id $userdef &>/dev/null || id "$username" &>/dev/null; then
  echo "SKIPPED"
else
  usermod -l "$username" $userdef
  usermod -m -d "/home/$username" "$username"
  groupmod -n "$username" $userdef
  chpasswd <<< "$username:$userpw"
  echo "OK"
fi

# While setup: show log to logged in user, will be overwritten by openhabian-setup.sh
echo "watch cat /boot/first-boot.log" > "$HOME/.bash_profile"

if [ -z "${wifi_ssid}" ]; then
  echo "$(timestamp) [openHABian] Setting up Ethernet connection... OK"
elif grep -q "openHABian" /etc/wpa_supplicant/wpa_supplicant.conf; then
  echo -n "$(timestamp) [openHABian] Setting up Wi-Fi connection... "
  if iwlist wlan0 scanning 2>&1 | grep -q "Interface doesn't support scanning"; then
    # wifi might be blocked
    rfkill unblock wifi
    ifconfig wlan0 up
    if iwlist wlan0 scanning 2>&1 | grep -q "Interface doesn't support scanning"; then
      echo "FAILED"
      echo -n "$(timestamp) [openHABian] I was not able to turn on the wifi \n Here is some more information: \n"
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
  elif grep -q "^${wifi_country^^}\s" /usr/share/zoneinfo/zone.tab; then
    wifi_country=${wifi_country^^}
  else
    echo "${wifi_country} is not a valid country code found in /usr/share/zoneinfo/zone.tab"
    echo "Defaulting to US"
    wifi_country="US"
  fi

  echo -e "# config generated by openHABian first boot setup" > /etc/wpa_supplicant/wpa_supplicant.conf
  echo -e "country=$wifi_country\\nctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\\nupdate_config=1" >> /etc/wpa_supplicant/wpa_supplicant.conf
  echo -e "network={\\n\\tssid=\"$wifi_ssid\"\\n\\tpsk=\"$wifi_psk\"\\n\\tkey_mgmt=WPA-PSK\\n}" >> /etc/wpa_supplicant/wpa_supplicant.conf

  sed -i "s/REGDOMAIN=.*/REGDOMAIN=${wifi_country}/g" /etc/default/crda

  if is_pi; then
    echo "OK, rebooting... "
    reboot
  else
    wpa_cli reconfigure &>/dev/null
    echo "OK"
  fi
fi

echo -n "$(timestamp) [openHABian] Ensuring network connectivity... "
cnt=0
until ping -c1 9.9.9.9 &>/dev/null || [ "$(wget -qO- http://www.msftncsi.com/ncsi.txt)" == "Microsoft NCSI" ]; do
  sleep 1
  cnt=$((cnt + 1))
  #echo -n ". "
  if [ $cnt -eq 100 ]; then
    echo "FAILED"
    if grep -q "openHABian" /etc/wpa_supplicant/wpa_supplicant.conf && iwconfig 2>&1 | grep -q "ESSID:off"; then
      echo -n "$(timestamp) [openHABian] I was not able to connect to the configured Wi-Fi. \n Please check your signal quality. Reachable Wi-Fi networks are: \n"
      iwlist wlan0 scanning | grep "ESSID" | sed 's/^\s*ESSID:/\t- /g'
      echo -n "$(timestamp) [openHABian] Please try again with your correct SSID and password. \n The following Wi-Fi configuration was used: \n"
      cat /etc/wpa_supplicant/wpa_supplicant.conf
      rm -f /etc/wpa_supplicant/wpa_supplicant.conf
    else
      echo "$(timestamp) [openHABian] The public internet is not reachable. Please check your network."
    fi
    fail_inprogress
  fi
done
echo "OK"

echo -n "$(timestamp) [openHABian] Waiting for dpkg/apt to get ready... "
until apt-get update &>/dev/null; do sleep 1; done
sleep 10  # Related to: https://github.com/openhab/openhabian/issues/441#issuecomment-448583415
echo "OK"

echo -n "$(timestamp) [openHABian] Updating repositories and upgrading installed packages... "
/usr/bin/apt-get --yes --fix-broken install &>/dev/null
apt-get --yes upgrade &>/dev/null
if [ $? -eq 0 ]; then echo "OK"; else echo "FAILED"; fail_inprogress; fi

if hash python3 2>/dev/null; then bash /boot/webif.bash reinsure_running; fi

echo -n "$(timestamp) [openHABian] Installing git package... "
/usr/bin/apt-get -y install git &>/dev/null
if [ $? -eq 0 ]; then echo "OK"; else echo "FAILED"; fail_inprogress; fi

echo -n "$(timestamp) [openHABian] Cloning myself from ${repositoryurl}, ${branch} branch... "
if [ -d /opt/openhabian/ ]; then cd /opt && rm -rf /opt/openhabian/; fi
git clone -q -b "$branch" "$repositoryurl" /opt/openhabian

if [ $? -eq 0 ]; then echo "OK"; else echo "FAILED"; fail_inprogress; fi
ln -sfn /opt/openhabian/openhabian-setup.sh /usr/local/bin/openhabian-config

echo "$(timestamp) [openHABian] Executing openhabian-setup.sh ${mode}... "
if (/bin/bash "$BASEDIR"/openhabian-setup.sh $mode); then
  rm -f /opt/openHABian-install-inprogress
  touch /opt/openHABian-install-successful
else
  fail_inprogress
fi
echo "$(timestamp) [openHABian] Execution of 'openhabian-setup.sh unattended' completed."

if [ "$mode" == "unattended_debug" ]; then
  service openhab2 status
  systemctl status --all
  wget -S --spider -t 3 --waitretry=4 http://${HOSTNAME}:8080/start/index 2>&1
fi

echo -n "$(timestamp) [openHABian] Waiting for openHAB to become ready on http://${HOSTNAME}:8080/..."
if tryUntil "wget -S --spider -t 3 --waitretry=4 http://${HOSTNAME}:8080/start/index 2>&1 | grep -q 'HTTP/1.1 200 OK'" 30 20; then echo "failed."; exit 1; fi
echo "OK"

echo "$(timestamp) [openHABian] Visit the openHAB dashboard now: http://${HOSTNAME}}:8080"
echo "$(timestamp) [openHABian] To gain access to a console, simply reconnect."
echo "$(timestamp) [openHABian] First time setup successfully finished."
sleep 12
if hash python3 2>/dev/null; then bash /boot/webif.bash inst_done; fi
sleep 12
if hash python3 2>/dev/null; then bash /boot/webif.bash cleanup; fi

# vim: filetype=sh
