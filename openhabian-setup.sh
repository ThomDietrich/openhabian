#!/usr/bin/env bash
# shellcheck disable=SC2034

# openHABian - hassle-free openHAB 2 installation and configuration tool
# for the Raspberry Pi and other Linux systems
#
# Documentation: https://www.openhab.org/docs/installation/openhabian.html
# Development: http://github.com/openhab/openhabian
# Discussion: https://community.openhab.org/t/13379
#


# Trap CTRL+C, CTRL+Z and quit singles
trap '' SIGINT SIGQUIT SIGTSTP

# Log with timestamp
timestamp() { date +"%F_%T_%Z"; }

# Make sure only root can run our script
echo -n "$(timestamp) [openHABian] Checking for root privileges... "
if [[ $EUID -ne 0 ]]; then
  echo ""
  echo "This script must be run as root. Did you mean 'sudo openhabian-config'?" 1>&2
  echo "More info: https://www.openhab.org/docs/installation/openhabian.html"
  exit 1
else
  echo "OK"
fi


source "/opt/openhabian/init.bash"

# script will be called with 'unattended' argument by openHABian images
if [[ "$1" = "unattended" ]]; then
  UNATTENDED=1
  SILENT=1
elif [[ "$1" = "unattended_debug" ]]; then
  UNATTENDED=1
  unset DEBUGMAX
elif [[ "$1" = "debug_maximum" ]]; then
  UNATTENDED=1
  DEBUGMAX=1
else
  INTERACTIVE=1
fi
export UNATTENDED SILENT DEBUGMAX INTERACTIVE

# Include all subscripts
# shellcheck source=/dev/null
for shfile in "$BASEDIR"/functions/*.bash; do source "$shfile"; done

# avoid potential crash when deleting directory we started from
OLDWD=$(pwd) && cd /opt || exit 1
if [[ -n "$UNATTENDED" ]]; then
  if [[ -n "$DEBUGMAX" ]]; then
    set -x
  fi
  # apt/dpkg commands will not try interactive dialogs
  export DEBIAN_FRONTEND=noninteractive
  apt-get -qq update 2>/dev/null
  load_create_config
  timezone_setting
  locale_setting
  hostname_change
  if is_pi; then memory_split; enable_rpi_audio; fi
  if is_pine64; then pine64_platform_scripts; fi
  if is_pine64; then pine64_fixed_mac; fi
  if is_pine64; then pine64_fix_systeminfo_binding; fi
  basic_packages
  needed_packages
  bashrc_copy
  vimrc_copy
  firemotd_setup
  # shellcheck disable=SC2154
  java_install_or_update "$JAVA_ARCH"
  openhab2_setup
  vim_openhab_syntax
  nano_openhab_syntax
  multitail_openhab_scheme
  srv_bind_mounts
  permissions_corrections
  misc_system_settings
# not per default for now
# if is_pione || is_pitwo || is_pithree || is_pithreeplus || is_pifour || is_pine64; then init_zram_mounts install; fi
  samba_setup
  clean_config_userpw
  frontail_setup
else
  apt-get update
  whiptail_check
  load_create_config
  ua-netinst_check
  openhabian_console_check
  openhabian_update_check
  while show_main_menu; do
    true
  done
  system_check_default_password
  echo -e "$(timestamp) [openHABian] We hope you got what you came for! See you again soon ;)"
fi
cd "$OLDWD" || exit 1

# vim: filetype=sh
