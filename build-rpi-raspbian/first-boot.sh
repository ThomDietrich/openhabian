#!/bin/bash

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
# shellcheck source=openhabian.raspbian.conf
source /etc/openhabian.conf
echo "OK"

echo -n "$(timestamp) [openHABian] Starting webserver... "
sh /boot/webif.sh start
echo "OK"

userdef="pi"
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
echo "watch cat /boot/first-boot.log" > "/home/$username/.bash_profile"

if [ -z "${wifi_ssid}" ]; then
  echo "$(timestamp) [openHABian] Setting up Ethernet connection... OK"
elif grep -q "openHABian" /etc/wpa_supplicant/wpa_supplicant.conf; then
  echo "$(timestamp) [openHABian] Setting up Wi-Fi connection... OK"
else
  echo -n "$(timestamp) [openHABian] Setting up Wi-Fi connection... "
  echo -e "# config generated by openHABian first boot setup" > /etc/wpa_supplicant/wpa_supplicant.conf
  echo -e "country=US\\nctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\\nupdate_config=1" >> /etc/wpa_supplicant/wpa_supplicant.conf
  echo -e "network={\\n\\tssid=\"$wifi_ssid\"\\n\\tpsk=\"$wifi_psk\"\\n\\tkey_mgmt=WPA-PSK\\n}" >> /etc/wpa_supplicant/wpa_supplicant.conf
  echo "OK, rebooting... "
  reboot
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
      echo ""
      echo "I was not able to connect to the configured Wi-Fi."
      echo "Please try again with your correct SSID and password."
      echo "Also check your signal quality. Available Wi-Fi networks:"
      iwlist wlan0 scanning | grep "ESSID" | sed 's/^\s*ESSID:/\t- /g'
      echo ""
    else
      echo "$(timestamp) [openHABian] The public internet is not reachable. Please check your network."
    fi
    fail_inprogress
  fi
done
echo "OK"

echo -n "$(timestamp) [openHABian] Waiting for dpkg/apt to get ready... "
until apt update &>/dev/null; do sleep 1; done
echo "OK"

echo -n "$(timestamp) [openHABian] Updating repositories and upgrading installed packages... "
apt update &>/dev/null
apt --yes upgrade &>/dev/null
if [ $? -eq 0 ]; then echo "OK"; else echo "FAILED"; fail_inprogress; fi

sh /boot/webif.sh stillrunning
echo -n "$(timestamp) [openHABian] Installing git package... "
apt update &>/dev/null
/usr/bin/apt -y install git &>/dev/null
if [ $? -eq 0 ]; then echo "OK"; else echo "FAILED"; fail_inprogress; fi

echo -n "$(timestamp) [openHABian] Cloning myself... "
/usr/bin/git clone -b master https://github.com/openhab/openhabian.git /opt/openhabian &>/dev/null
#/usr/bin/git clone -b develop https://github.com/openhab/openhabian.git /opt/openhabian &>/dev/null
if [ $? -eq 0 ]; then echo "OK"; else echo "FAILED"; fail_inprogress; fi
ln -sfn /opt/openhabian/openhabian-setup.sh /usr/local/bin/openhabian-config

echo "$(timestamp) [openHABian] Executing 'openhabian-setup.sh unattended'... "
if (/bin/bash /opt/openhabian/openhabian-setup.sh unattended); then
#if (/bin/bash /opt/openhabian/openhabian-setup.sh unattended_debug); then
  systemctl start openhab2.service
  rm -f /opt/openHABian-install-inprogress
  touch /opt/openHABian-install-successful
else
  fail_inprogress
fi
echo "$(timestamp) [openHABian] Execution of 'openhabian-setup.sh unattended' completed."

echo -n "$(timestamp) [openHABian] Waiting for openHAB to become ready... "
until wget -S --spider http://localhost:8080 2>&1 | grep -q 'HTTP/1.1 200 OK'; do
  sleep 1
done
echo "OK"

echo "$(timestamp) [openHABian] Visit the openHAB dashboard now: http://$hostname:8080"
echo "$(timestamp) [openHABian] To gain access to a console, simply reconnect."
echo "$(timestamp) [openHABian] First time setup successfully finished."
sleep 10
sh /boot/webif.sh inst_done
sleep 10
sh /boot/webif.sh cleanup

# vim: filetype=sh
