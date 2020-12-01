#!/usr/bin/env bash

## Configure WiFi setup on current system
## Valid arguments: "setup" or "disable"
##
##    configure_wifi(String option)
##
configure_wifi() {
  if [[ -z $INTERACTIVE ]]; then
    echo "$(timestamp) [openHABian] WiFi setup must be run in interactive mode! Canceling WiFi setup!"
    return 0
  fi

  local disabledText
  local enabledText
  local questionText
  local wifiConfig
  local wifiCountry
  local wifiNetworkList
  local wifiPassword
  local wifiSSID

  disabledText="WiFi is currently disabled on your box.\\n\\nATTENTION:\\nWould you like to enable WiFi and continue setup?"
  enabledText="WiFi is currently enabled on your box.\\n\\nATTENTION:\\nWould you like to disable WiFi and use Ethernet?"
  questionText="We could not detect any WiFi hardware on your system.\\nYou are not running any of supported systems (RPi4, RPi3, RPi0W) which have WiFi builtin. However, we cannot detect all possible WiFi hardware.\\nDo you really want to continue and have openHABian try to setup WiFi?"

  echo -n "$(timestamp) [openHABian] Beginning WiFi configuration... "

  if ! is_pizerow && ! is_pithree && ! is_pithreeplus && ! is_pifour; then
    if (whiptail --title "No WiFi Hardware Detected" --yesno "$questionText" 10 80); then echo "OK"; else echo "CANCELED"; return 0; fi
  else
    echo "OK"
  fi

  if [[ $1 == "setup" ]]; then
    if grep -qsE "^[[:space:]]*dtoverlay=(pi3-)?disable-wifi" /boot/config.txt; then
      if (whiptail --title "WiFi is currently disabled" --yesno "$disabledText" 10 80); then
        cond_redirect enable_disable_wifi "enable"
      else
        echo "CANCELED"
        return 0
      fi
    fi

    if is_pifour || is_pithree || is_pithreeplus || is_pizerow; then
      if ! dpkg -s 'firmware-brcm80211' &> /dev/null; then
        echo -n "$(timestamp) [openHABian] Installing WiFi firmware... "
        if cond_redirect apt-get install --yes firmware-brcm80211; then echo "OK"; else echo "FAILED"; return 1; fi
      fi
    fi

    if ! dpkg -s 'wpasupplicant' 'wireless-tools' &> /dev/null; then
      echo -n "$(timestamp) [openHABian] Installing WiFi prerequisites (wpasupplicant, wireless-tools)... "
      if cond_redirect apt-get install --yes wpasupplicant wireless-tools; then echo "OK"; else echo "FAILED"; return 1; fi
    fi

    echo -n "$(timestamp) [openHABian] Checking if WiFi is working... "
    if iwlist wlan0 scan |& grep -qs "Interface doesn't support scanning"; then
      # WiFi might be blocked
      rfkill unblock wifi
      ip link set wlan0 up
      if iwlist wlan0 scan |& grep -qs "Interface doesn't support scanning"; then
        echo "FAILED"
        echo -e "\\nI was not able to turn on the WiFi\\nHere is some more information:\\n"
        rfkill list all
        ip a
        return 1
      else
        echo "OK"
      fi
    else
      echo "OK"
    fi

    echo -n "$(timestamp) [openHABian] Configuring WiFi... "
    wifiNetworkList="$(iwlist wlan0 scan | grep ESSID | sed -e 's/^[[:space:]]*ESSID://g; s/"//g; /^[[:space:]]*$/d')"
    if [[ -z $wifiNetworkList ]]; then echo "FAILED (no networks found)"; return 1; fi
    if ! wifiSSID="$(whiptail --title "Wifi Setup" --inputbox "\\nWhich WiFi network would you like do you want to connect to?\\n\\nNetwork List:\\n${wifiNetworkList}" 20 80 3>&1 1>&2 2>&3)"; then echo "CANCELED"; return 0; fi
    if [[ -z $wifiSSID ]]; then echo "FAILED (blank SSID)"; return 1; fi
    if ! wifiPassword="$(whiptail --title "Wifi Setup" --passwordbox "\\nWhat's the password for ${wifiSSID}?" 9 80 3>&1 1>&2 2>&3)"; then echo "CANCELED"; return 0; fi
    if ! wifiConfig="$(wpa_passphrase "${wifiSSID}" "${wifiPassword}")"; then echo "FAILED (${wifiConfig})"; return 1; fi
    if ! wifiCountry="$(whiptail --title "Wifi Setup" --inputbox "\\nPlease enter the two-letter country code matching your region (US, DE, NZ, AU)...\\n\\nSee https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2" 12 80 3>&1 1>&2 2>&3)"; then echo "CANCELED"; return 0; fi
    # Check if the country code is valid, valid country codes are followed by spaces in /usr/share/zoneinfo/zone.tab
    if grep -qs "^${wifiCountry^^}[[:space:]]" /usr/share/zoneinfo/zone.tab; then
      wifiCountry="${wifiCountry^^}"
    else
      echo "FAILED (${wifiCountry} is not a valid country code found in '/usr/share/zoneinfo/zone.tab')"
      return 1
    fi
    if ! cond_redirect mkdir -p /etc/wpa_supplicant; then echo "FAILED (create directory)"; return 1; fi
    if ! echo -e "# WiFi configuration generated by openHABian\\ncountry=$wifiCountry\\nctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\\nupdate_config=1\\n# Network configuration was created by wpa_passphrase to ensure correct handling of special characters\\n${wifiConfig//\}/\\tkey_mgmt=WPA-PSK\\n\}}" > /etc/wpa_supplicant/wpa_supplicant.conf; then echo "FAILED (create configuration)"; return 1; fi
    if cond_redirect sed -i -e 's|REGDOMAIN=.*$|REGDOMAIN='"${wifiCountry}"'|g' /etc/default/crda; then echo "OK"; else echo "FAILED (set country)"; return 1; fi

    echo -n "$(timestamp) [openHABian] Configuring network... "
    if grep -qs "wlan0" /etc/network/interfaces; then
      cond_echo "\\nNot writing to '/etc/network/interfaces', wlan0 entry already available. You might need to check, adopt or remove these lines."
    else
      echo -e "\\nallow-hotplug wlan0\\niface wlan0 inet manual\\nwpa-roam /etc/wpa_supplicant/wpa_supplicant.conf\\niface default inet dhcp" >> /etc/network/interfaces
    fi
    if ! cond_redirect wpa_cli reconfigure; then echo "FAILED (reconfigure)"; return 1; fi
    if ! cond_redirect ip link set wlan0 down; then echo "FAILED (down)"; return 1; fi
    if cond_redirect ip link set wlan0 up; then echo "OK (reboot now)"; else echo "FAILED (up)"; return 1; fi

    whiptail --title "Operation Successful!" --msgbox "Setup was successful. The credentials provided were not tested. Please reboot now." 7 80
  elif [[ $1 == "disable" ]]; then
    if (whiptail --title "WiFi is currently enabled" --defaultno --yesno "$enabledText" 10 80); then
      cond_redirect enable_disable_wifi "disable"
      echo -n "$(timestamp) [openHABian] Cleaning up old WiFi configuration... "
      if cond_redirect sed -i -e '/allow-hotplug wlan0/d; /iface wlan0 inet manual/d; /wpa-roam \/etc\/wpa_supplicant\/wpa_supplicant.conf/d; /iface default inet dhcp/d' /etc/network/interfaces; then echo "OK (reboot now)"; else echo "FAILED"; return 1; fi
      whiptail --title "Operation Successful!" --msgbox "Setup was successful. Please reboot now." 7 80
    else
      echo "CANCELED"
      return 0
    fi
  fi
}


## Install comitup WiFi hotspot demon
## Valid arguments: "setup" or "disable"
## see https://davesteele.github.io/comitup/ppa.html and
## https://gist.github.com/jjsanderson/ab2407ab5fd07feb2bc5e681b14a537a
##
##    setup_hotspot(String option)
##
setup_hotspot() {

  if [[ $1 == "install" ]]; then
    echo -n "$(timestamp) [openHABian] Installing Comitup hotspot... "
    # get from source - the comitup package in Buster is 2yrs old
    echo "deb http://davesteele.github.io/comitup/repo comitup main" > /etc/apt/sources.list.d/comitup.list
    if ! cond_redirect apt-get --quiet update; then echo "FAILED (update apt lists)"; return 1; fi

    if ! cp "${BASEDIR:-/opt/openhabian}"/includes/comitup.conf /etc/comitup.conf; then echo "FAILED (comitup config)"; return 1; fi
    if cond_redirect apt install --yes -o Dpkg::Options::=--force-confdef comitup; then echo "OK"; else echo "FAILED"; return 1; fi
#    echo "denyinterfaces wlan0 eth0" >> /etc/dhcpcd.conf
    sed -i '3 i dhcp=internal' /etc/NetworkManager/NetworkManager.conf
  elif [[ $1 == "disable" ]]; then
    echo -n "$(timestamp) [openHABian] Uninstalling hotspot... "
    if cond_redirect apt purge --yes comitup; then echo "OK"; else echo "FAILED"; return 1; fi
  fi
}

