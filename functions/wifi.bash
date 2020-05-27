#!/usr/bin/env bash

wifi_setup() {
  local question="We could not detect any WiFi hardware on your system.\\nYou are not running any of supported systems RPi4, RPi3, RPi0W or Pine to have WiFi builtin, but we cannot detect all possible WiFi hardware.\\nDo you really want to continue and have openHABian try to setup WiFi ?"
  echo -n "$(timestamp) [openHABian] Setting up WiFi ... "

  if ! is_pifour && ! is_pithree && ! is_pithreeplus && ! is_pizerow && ! is_pine64; then
    if [ -n "$INTERACTIVE" ]; then
      if ! (whiptail --title "No WiFi Hardware Detected" --yesno "$question" 10 80); then echo "FAILED"; return 1; fi
    fi
  fi

  if [ -n "$INTERACTIVE" ]; then
    if grep -q "^[[:space:]]*dtoverlay=disable-wifi" /boot/config.txt; then
      if (whiptail --title "WiFi is currently disabled" --yesno "WiFi is currently disabled on your box. Enable ?" 7 55); then 
        cond_echo "Removing 'dtoverlay=disable-wifi' from /boot/config.txt"
        sed -i '/dtoverlay=disable-wifi/d' /boot/config.txt
	whiptail --title "Operation Successful!" --msgbox "Please reboot now to enable your WiFi hardware.\\nRun openhabian-config and select this menu option again to continue." 8 75
      fi
      return 0
    else
      if (whiptail --title "WiFi is currently ON" --defaultno --yesno "WiFi is currently enabled on your box.\\n\\nATTENTION:\\nDo you want to disable it ?" 10 50); then 
        cond_echo "Adding 'dtoverlay=disable-wifi' to /boot/config.txt (RPi0W/3/4)"
        echo "dtoverlay=disable-wifi" >> /boot/config.txt
	whiptail --title "Operation successful!" --msgbox "Please reboot now to have your WiFi hardware disabled." 7 70
        return 0
      fi
    fi

    if ! SSID=$(whiptail --title "Wifi Setup" --inputbox "Which Wifi (SSID) do you want to connect to?" 10 60 3>&1 1>&2 2>&3); then return 1; fi
    if ! PASS=$(whiptail --title "Wifi Setup" --inputbox "What's the password for that Wifi?" 10 60 3>&1 1>&2 2>&3); then return 1; fi
    # use wpa_passphrase to escape the password, it handles special characters - how
    if ! WNET=$(wpa_passphrase "${SSID}" "${PASS}"); then
      whiptail --title "WiFi Setup" --msgbox "wpa_passphrase failed,\\n \"${WNET}\"" 10 60
      echo "wpa_passphrase failed, \"${WNET}\""; return 1
    fi
    if ! WIFICOUNTRY=$(whiptail --title "Wifi Setup" --inputbox "Please enter the two-letter country code matching your region eg. US DE NZ AU...\\nSee https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2" 10 60 3>&1 1>&2 2>&3); then return 1; fi
    # check the user input for the country code
    # check: from the start of line, the uppercased input must be followed by a whitespace
    if grep -q "^${WIFICOUNTRY^^}\\s" /usr/share/zoneinfo/zone.tab; then
      WIFICOUNTRY=${WIFICOUNTRY^^}
    else
      whiptail --title "WiFi Setup" --msgbox "${WIFICOUNTRY} is not a valid country code found in /usr/share/zoneinfo/zone.tab" 10 60
      echo "${WIFICOUNTRY} is not a valid country code found in /usr/share/zoneinfo/zone.tab"; return 1
    fi
  else
    echo -n "Setting default SSID and password in 'wpa_supplicant.conf' "
    SSID="myWiFiSSID"
    PASS="myWiFiPassword"
  fi
  if is_pifour || is_pithree || is_pithreeplus; then cond_redirect apt-get -y install firmware-brcm80211; fi
  if is_pithreeplus || is_pifour; then
    if iwlist wlan0 scanning 2>&1 | grep -q "Interface doesn't support scanning"; then
      # wifi might be blocked
      rfkill unblock wifi
      ifconfig wlan0 up
      if iwlist wlan0 scanning 2>&1 | grep -q "Interface doesn't support scanning"; then
        echo "FAILED"
        echo ""
        echo "I was not able to turn on the wifi"
        echo "Here is some more information"
        echo ""
        rfkill list all
        ifconfig
        return 1
      fi
    fi
  fi
  cond_redirect apt-get -y install wpasupplicant wireless-tools
  mkdir -p /etc/wpa_supplicant
  echo -e "# config generated by openHABian wifi function" > /etc/wpa_supplicant/wpa_supplicant.conf
  echo -e "country=$WIFICOUNTRY\\nctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\\nupdate_config=1" >> /etc/wpa_supplicant/wpa_supplicant.conf
  echo -e "# network config created by wpa_passphrase to ensure correct handling of special characters\\n${WNET//\}/\\tkey_mgmt=WPA-PSK\\n\}}" >> /etc/wpa_supplicant/wpa_supplicant.conf

  sed -i "s/REGDOMAIN=.*/REGDOMAIN=${WIFICOUNTRY}/g" /etc/default/crda

  if grep -q "wlan0" /etc/network/interfaces; then
    cond_echo ""
    cond_echo "Not writing to '/etc/network/interfaces', wlan0 entry already available. You might need to check, adopt or remove these lines."
    cond_echo ""
  else
    echo -e "\\nallow-hotplug wlan0\\niface wlan0 inet manual\\nwpa-roam /etc/wpa_supplicant/wpa_supplicant.conf\\niface default inet dhcp" >> /etc/network/interfaces
  fi
  cond_redirect wpa_cli reconfigure
  cond_redirect ifdown wlan0
  cond_redirect ifup wlan0
  if [ -n "$INTERACTIVE" ]; then
    whiptail --title "Operation Successful!" --msgbox "Setup was successful. Your WiFi credentials were NOT tested. Please reboot now." 15 80
  fi
  echo "OK (Reboot needed)"
}
