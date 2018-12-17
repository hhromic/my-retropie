#!/usr/bin/env bash
# Automated management script for custom RetroPie installations.
# script by github.com/hhromic

#===============================================================================
# Files and directories

# bluez storage directory
BLUEZ_STORAGE_DIR=/var/lib/bluetooth

# bluez device info file (args: adapter, device)
BLUEZ_INFO_FILE=$BLUEZ_STORAGE_DIR/%s/%s/info

# bluez device cache file (args: adapter, device)
BLUEZ_CACHE_FILE=$BLUEZ_STORAGE_DIR/%s/cache/%s

# RetroPie base directory
RETROPIE_BASE_DIR=$HOME/RetroPie-Setup

# config files base directory
CONFIGS_BASE_DIR=/opt/retropie/configs

# system base directory (args: system)
SYSTEM_BASE_DIR=$CONFIGS_BASE_DIR/%s

# retropie autoconf file
AUTOCONF_FILE=$CONFIGS_BASE_DIR/all/autoconf.cfg

# runcommand config file
RUNCOMMAND_CONFIG_FILE=$CONFIGS_BASE_DIR/all/runcommand.cfg

# emulators config file (args: system)
EMULATORS_FILE=$SYSTEM_BASE_DIR/emulators.cfg

# video modes config file
VIDEO_MODES_FILE=$CONFIGS_BASE_DIR/all/videomodes.cfg

# retroarch config file
RETROARCH_CONFIG_FILE=$CONFIGS_BASE_DIR/all/retroarch.cfg

# shaders base directory
SHADERS_BASE_DIR=$CONFIGS_BASE_DIR/all/retroarch/shaders

# shaders directory
SHADERS_DIR=$SHADERS_BASE_DIR/shaders

# shaders presets directory
SHADERS_PRESETS_DIR=$SHADERS_BASE_DIR/presets

# retroarch joypad autoconfig directory
AUTOCONFIG_DIR=$CONFIGS_BASE_DIR/all/retroarch/autoconfig

# emulationstation input config file
ES_INPUT_FILE=$CONFIGS_BASE_DIR/all/emulationstation/es_input.cfg

# emulationstation settings file
ES_SETTINGS_FILE=$CONFIGS_BASE_DIR/all/emulationstation/es_settings.cfg

#===============================================================================
# Raspbian Configuration

# device hostname
DEVICE_HOSTNAME=retropie

# device timezone
DEVICE_TIMEZONE=Etc/UTC

# apt packages to be installed
declare -a APT_PACKAGES

# info data for bluetooth devices
declare -A BLUETOOTH_DEVICE_INFO

# cache data for bluetooth devices
declare -A BLUETOOTH_DEVICE_CACHE

# device-tree overlays
declare -A DTOVERLAY

#===============================================================================
# RetroPie Configuration

# RetroPie git repository URL
RETROPIE_REPOSITORY=https://github.com/RetroPie/RetroPie-Setup

# packages to be installed from binary
declare -a PACKAGES_BINARY

# packages to be installed from source
declare -a PACKAGES_SOURCE

# default emulators for systems
declare -A EMULATOR

# default video modes for emulators
declare -A VIDEO_MODE

# shader preset types for libretro core names
declare -A SHADER_PRESET_TYPE

# shader presets for shader preset types
declare -A SHADER_PRESET

# autoconfigs for retroarch joypads
declare -A JOYPAD_AUTOCONFIG

# joypad indices for retroarch players
declare -A JOYPAD_INDEX

# joypad remaps for systems/libretro core names
declare -A JOYPAD_REMAP

# emulationstation input config
declare ES_INPUT

# emulationstation settings
declare ES_SETTINGS

#===============================================================================
# Helpers

function print() {
  local -r _format=$1
  shift
  # shellcheck disable=SC2059
  printf "$_format" "$@"
}

function new_line() {
  print "%s" $'\n'
}

function println() {
  print "$@" && new_line
}

function ansi_code() {
  local _token
  local -i _code
  for _token in "$@"; do
    _code=-1
    case $_token in
      reset)       _code=0 ;;
      bold)        _code=1 ;;
      underline)   _code=4 ;;
      blink)       _code=5 ;;
      reverse)     _code=7 ;;
      invisible)   _code=8 ;;
      fg_black)    _code=30 ;;
      fg_red)      _code=31 ;;
      fg_green)    _code=32 ;;
      fg_yellow)   _code=33 ;;
      fg_blue)     _code=34 ;;
      fg_magenta)  _code=35 ;;
      fg_cyan)     _code=36 ;;
      fg_white)    _code=37 ;;
      bg_black)    _code=40 ;;
      bg_red)      _code=41 ;;
      bg_green)    _code=42 ;;
      bg_yellow)   _code=43 ;;
      bg_blue)     _code=44 ;;
      bg_magenta)  _code=45 ;;
      bg_cyan)     _code=46 ;;
      bg_white)    _code=47 ;;
    esac
    [[ $_code -ge 0 ]] && print $'\e'"[%dm" "$_code"
  done
}

function confirm() {
  local _ans
  ansi_code reset && new_line && print "%s (" "$@" &&
  ansi_code fg_green && print "y" &&
  ansi_code reset && print "/" &&
  ansi_code fg_red && print "[N]" &&
  ansi_code reset && print ") "
  read -r _ans
  case $_ans in
    y*|Y*) return 0 ;;
    *) return 1 ;;
  esac
}

function show_banner() {
  ansi_code reset && new_line &&
  ansi_code bold fg_red &&
  println "= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =" &&
  ansi_code fg_yellow && println "$@" &&
  ansi_code fg_red &&
  println "= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =" &&
  ansi_code reset
}

function show_message() {
  ansi_code reset && new_line &&
  ansi_code fg_cyan && print ">>> " &&
  ansi_code bold && println "$@" && ansi_code reset
}

function show_variables() {
  function _show_var() {
    local -r _label=$1
    shift
    ansi_code reset fg_magenta && print "%s" "$_label" &&
    ansi_code bold && print " = " &&
    ansi_code reset && println "%s " "$@"
  }
  function _show_arr() {
    local -r _label=$1
    local _keys
    local _key
    local _value
    ansi_code reset fg_magenta && print "%s" "$_label" &&
    ansi_code bold && println " = " && ansi_code reset
    eval _keys=\(\"\$\{!"$2"\[@\]\}\"\)
    for _key in "${_keys[@]}"; do
      eval _value=\"\$\{"$2"\[\"\$_key\"\]\}\"
      print "[" && ansi_code bold && print "%s" "$_key" &&
      ansi_code reset && println "]=%s" "$_value"
    done
  }

  show_message "Files and directories" && new_line &&
  _show_var "BLUEZ_STORAGE_DIR     " "$BLUEZ_STORAGE_DIR" &&
  _show_var "BLUEZ_INFO_FILE       " "$BLUEZ_INFO_FILE" &&
  _show_var "BLUEZ_CACHE_FILE      " "$BLUEZ_CACHE_FILE" &&
  _show_var "RETROPIE_BASE_DIR     " "$RETROPIE_BASE_DIR" &&
  _show_var "CONFIGS_BASE_DIR      " "$CONFIGS_BASE_DIR" &&
  _show_var "SYSTEM_BASE_DIR       " "$SYSTEM_BASE_DIR" &&
  _show_var "AUTOCONF_FILE         " "$AUTOCONF_FILE" &&
  _show_var "RUNCOMMAND_CONFIG_FILE" "$RUNCOMMAND_CONFIG_FILE" &&
  _show_var "VIDEO_MODES_FILE      " "$VIDEO_MODES_FILE" &&
  _show_var "RETROARCH_CONFIG_FILE " "$RETROARCH_CONFIG_FILE" &&
  _show_var "SHADERS_BASE_DIR      " "$SHADERS_BASE_DIR" &&
  _show_var "SHADERS_DIR           " "$SHADERS_DIR" &&
  _show_var "SHADERS_PRESETS_DIR   " "$SHADERS_PRESETS_DIR" &&
  _show_var "AUTOCONFIG_DIR        " "$AUTOCONFIG_DIR" &&
  _show_var "ES_INPUT_FILE         " "$ES_INPUT_FILE" &&
  _show_var "ES_SETTINGS_FILE      " "$ES_SETTINGS_FILE" &&

  show_message "Raspbian configuration" && new_line &&
  _show_var "DEVICE_HOSTNAME       " "$DEVICE_HOSTNAME" &&
  _show_var "DEVICE_TIMEZONE       " "$DEVICE_TIMEZONE" &&
  _show_arr "APT_PACKAGES          " "APT_PACKAGES" &&
  _show_arr "BLUETOOTH_DEVICE_INFO " "BLUETOOTH_DEVICE_INFO" &&
  _show_arr "BLUETOOTH_DEVICE_CACHE" "BLUETOOTH_DEVICE_CACHE" &&
  _show_arr "DTOVERLAY             " "DTOVERLAY" &&

  show_message "RetroPie configuration" && new_line &&
  _show_var "RETROPIE_REPOSITORY   " "$RETROPIE_REPOSITORY" &&
  _show_var "PACKAGES_BINARY       " "${PACKAGES_BINARY[@]}" &&
  _show_var "PACKAGES_SOURCE       " "${PACKAGES_SOURCE[@]}" &&
  _show_arr "EMULATOR              " "EMULATOR" &&
  _show_arr "VIDEO_MODE            " "VIDEO_MODE" &&
  _show_arr "SHADER_PRESET_TYPE    " "SHADER_PRESET_TYPE" &&
  _show_arr "SHADER_PRESET         " "SHADER_PRESET" &&
  _show_arr "JOYPAD_AUTOCONFIG     " "JOYPAD_AUTOCONFIG" &&
  _show_arr "JOYPAD_INDEX          " "JOYPAD_INDEX" &&
  _show_arr "JOYPAD_REMAP          " "JOYPAD_REMAP" &&
  _show_var "ES_INPUT              " $'\n'"$ES_INPUT" &&
  _show_var "ES_SETTINGS           " $'\n'"$ES_SETTINGS"
}

function have_bluetooth() {
  [[ ${#BLUETOOTH_DEVICE_INFO[@]} -gt 0 ]] || [[ -n $HAVE_BLUETOOTH ]]
}

#===============================================================================
# Actions helpers

function update_apt() {
  sudo apt-get -y update
}

function update_apt_packages() {
  sudo apt-get -y dist-upgrade
}

function install_apt_packages() {
  sudo apt-get -y install "$@"
}

function clean_apt() {
  sudo apt-get -y clean
}

function run_retropie_packages() {
  sudo "$RETROPIE_BASE_DIR"/retropie_packages.sh "$@"
}

function run_systemctl() {
  sudo systemctl "$@"
}

function enable_apt_suite() {
  local -r _suite=$1
  sudo bash <<EOF
grep "^deb" /etc/apt/sources.list | awk "{\\\$3=\"$_suite\"}1" \
  > /etc/apt/sources.list.d/"$_suite".list || exit
EOF
}

function set_apt_preference() {
  local -r _filename=$1
  local -r _package=$2
  local -r _suite=$3
  local -r _priority=$4
  sudo bash <<EOF
cat > /etc/apt/preferences.d/"$_filename" <<EOF_2
Package: $_package
Pin: release a=$_suite
Pin-Priority: $_priority
EOF_2
EOF
}

function set_hostname() { # adapted from raspi-config
  local -r _hostname=$1
  local _current
  _current=$(tr -d $'\t'$'\n'$'\r' < /etc/hostname)
  sudo bash <<EOF
printf "%s"\$'\\n' "$_hostname" > /etc/hostname || exit
sed -e "s/127.0.1.1.*$_current/127.0.1.1"\$'\\t'"$_hostname/g" \
  -i /etc/hosts || exit
EOF
}

function set_timezone() { # adapted from raspi-config
  local -r _timezone=$1
  sudo bash <<EOF
rm -f /etc/localtime || exit
printf "%s"\$'\\n' "$_timezone" > /etc/timezone || exit
dpkg-reconfigure -f noninteractive tzdata || exit
EOF
}

function disable_network_wait() { # adapted from raspi-config
  sudo bash <<"EOF"
if [[ -f /etc/systemd/system/dhcpcd.service.d/wait.conf ]]; then
  rm -f /etc/systemd/system/dhcpcd.service.d/wait.conf || exit
fi
EOF
}

function install_package_from_binary() {
  local -r _package=$1
  local _action
  for _action in depends install_bin configure; do
    run_retropie_packages "$_package" "$_action" || return
  done
}

function install_package_from_source() {
  local -r _package=$1
  run_retropie_packages "$_package" clean || return
  run_retropie_packages "$_package" || return
}

function get_bluetooth_adapters() {
  hciconfig | grep -o -E "([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}" \
    | tr "[:lower:]" "[:upper:]"
}

function write_bluetooth_info() {
  local -r _adapter=$1
  local -r _device=$2
  local -r _data=$3
  local _filename
  _filename=$(print "$BLUEZ_INFO_FILE" "$_adapter" "$_device")
  sudo bash <<EOF
umask 0077
mkdir -p "${_filename%/*}" || exit
printf "$_data"$'\\n' > "$_filename" || exit
EOF
}

function write_bluetooth_cache() {
  local -r _adapter=$1
  local -r _device=$2
  local -r _data=$3
  local _filename
  _filename=$(print "$BLUEZ_CACHE_FILE" "$_adapter" "$_device")
  sudo bash <<EOF
umask 0077
mkdir -p "${_filename%/*}" || exit
printf "$_data"$'\\n' > "$_filename" || exit
EOF
}

function set_autoconf_option() {
  local -r _option=$1
  local -r _value=$2
  [[ ! -f $AUTOCONF_FILE ]] && return
  sed -e "s/^.*$_option.*$/$_option = \"$_value\"/g" \
    -i "$AUTOCONF_FILE" || return
}

function set_runcommand_option() {
  local -r _option=$1
  local -r _value=$2
  [[ ! -f $RUNCOMMAND_CONFIG_FILE ]] && return
  sed -e "s/^.*$_option.*$/$_option = \"$_value\"/g" \
    -i "$RUNCOMMAND_CONFIG_FILE" || return
}

function set_retroarch_option() {
  local -r _option=$1
  local -r _value=$2
  [[ ! -f $RETROARCH_CONFIG_FILE ]] && return
  sed -e "s/^.*$_option.*$/$_option = \"$_value\"/g" \
    -i "$RETROARCH_CONFIG_FILE" || return
}

function write_shader_preset() {
  local -r _core_name=$1
  local -r _preset=$2
  local -r _filename="$SHADERS_PRESETS_DIR"/"$_core_name"/"$_core_name".glslp
  mkdir -p "${_filename%/*}" || return
  println "$_preset" > "$_filename" || return
}

function write_joypad_autoconfig() {
  local -r _joypad=$1
  local -r _autoconfig=$2
  println "$_autoconfig" > "$AUTOCONFIG_DIR"/"$_joypad".cfg || return
}

function write_joypad_remap() {
  local -r _system=$1
  local -r _core_name=$2
  local -r _remap=$3
  local _filename
  _filename=$(print "$SYSTEM_BASE_DIR" "$_system")
  _filename+=/"$_core_name"/"$_core_name".rmp
  mkdir -p "${_filename%/*}" || return
  println "$_remap" > "$_filename" || return
}

function set_rpiconfig_option() {
  local -r _option=$1
  local -r _value=$2
  [[ ! -f /boot/config.txt ]] && return
  sudo bash <<EOF
if grep -q "^$_option=" /boot/config.txt 2>/dev/null; then
  sed -e "/^$_option=/ c\\$_option=$_value" -i /boot/config.txt || exit
else
  printf "%s=%s"$'\\n' "$_option" "$_value" >> /boot/config.txt || exit
fi
EOF
}

function set_rpiconfig_dtoverlay() {
  local -r _dtoverlay=$1
  local _params=$2
  [[ ! -f /boot/config.txt ]] && return
  [[ -n $_params ]] && _params=":$_params"
  sudo bash <<EOF
if grep -E -q '^dtoverlay=$_dtoverlay([,:]|\$)' /boot/config.txt 2>/dev/null; then
  sed -E "/^dtoverlay=$_dtoverlay([,:]|\$)/ c\\dtoverlay=$_dtoverlay$_params" -i /boot/config.txt || exit
else
  printf "dtoverlay=%s%s"$'\\n' "$_dtoverlay" "$_params" >> /boot/config.txt || exit
fi
EOF
}

function enable_autologin_skip_login() {
  sudo bash <<"EOF"
mkdir -p /etc/systemd/system/autologin@.service.d || exit
cat > /etc/systemd/system/autologin@.service.d/skip-login.conf <<EOF_2 || exit
[Service]
ExecStart=
EOF_2
grep "^ExecStart=-/sbin/agetty --autologin [^[:space:]]*" /etc/systemd/system/autologin@.service \
  | sed "s#^ExecStart=-/sbin/agetty --autologin [^[:space:]]*#\\0 --skip-login#" \
  >> /etc/systemd/system/autologin@.service.d/skip-login.conf
EOF
}

function configure_kcmdline() {
  [[ ! -f /boot/cmdline.txt ]] && return
  sudo bash <<"EOF"
function _set_option() {
  local -r _option=$1
  local _value=$2
  local -i _found=0
  local -i _idx=0
  [[ -n $_value ]] && _value="=$_value"
  while [[ $_idx -lt ${#CMDLINE[@]} ]]; do
    if [[ ${CMDLINE[$_idx]} =~ ^$_option(=|$) ]]; then
      CMDLINE[$_idx]="$_option$_value"
      _found=1
    fi
    ((_idx++))
  done
  [[ $_found -eq 0 ]] && CMDLINE[$_idx]="$_option$_value"
}
mapfile -t CMDLINE < <(tr " " $'\n' < /boot/cmdline.txt)
_set_option "console" "tty3"
_set_option "logo.nologo"
_set_option "quiet"
_set_option "loglevel" "3"
_set_option "vt.global_cursor_default" "0"
_set_option "plymouth.enable" "0"
N_CMDLINE=$(sort -u <(for l in "${CMDLINE[@]}"; do printf "%s"$'\n' "$l"; done))
printf "%s"$'\n' "${N_CMDLINE//$'\n'/ }" > /boot/cmdline.txt
EOF
}

#===============================================================================
# Actions

function action_apt_setup() {
  local _bluez_packages
  show_banner "APT Setup"

  if have_bluetooth; then
    # enable testing suite
    show_message "Enabling 'testing' suite ..."
    enable_apt_suite "testing" || return

    # configure testing suite preference
    show_message "Configuring 'testing' suite preference ..."
    set_apt_preference "testing" "*" "testing" "-10"

    # configure bluez packages preference
    show_message "Configuring bluez packages preference ..."
    _bluez_packages=(
      bluetooth bluez bluez-cups bluez-hcidump bluez-obexd bluez-test-scripts
      bluez-test-tools libbluetooth-dev libbluetooth3 bluez-firmware
    )
    set_apt_preference "bluez" "${_bluez_packages[*]}" "testing" "900"
  fi
}

function action_raspbian_update() {
  show_banner "Raspbian Update"

  # update apt
  show_message "Updating APT ..."
  update_apt || return

  # update apt packages
  show_message "Updating APT packages ..."
  update_apt_packages || return
}

function action_raspbian_setup() {
  show_banner "Raspbian Setup"

  # install required apt packages
  show_message "Installing required APT packages ..."
  install_apt_packages git ca-certificates || return

  # install apt packages
  show_message "Install APT packages ..."
  install_apt_packages "${APT_PACKAGES[@]}" || return

  # configure device hostname
  show_message "Configuring device hostname to '%s' ..." "$DEVICE_HOSTNAME"
  set_hostname "$DEVICE_HOSTNAME" || return

  # configure device timezone
  show_message "Configuring device timezone to '%s' ..." "$DEVICE_TIMEZONE"
  set_timezone "$DEVICE_TIMEZONE" || return

  # disable network wait during boot
  show_message "Disabling network wait during boot ..."
  disable_network_wait || return
}

function action_retropie_setup() {
  show_banner "RetroPie Setup"

  # clone RetroPie-Setup repository
  show_message "Cloning Retropie-Setup into '%s' ..." "$RETROPIE_BASE_DIR"
  git clone "$RETROPIE_REPOSITORY" "$RETROPIE_BASE_DIR" || return
}

function action_retropie_update() {
  show_banner "RetroPie Update"

  # update the local RetroPie-Setup repository
  show_message "Updating the local Retropie-Setup repository ..."
  git -C "$RETROPIE_BASE_DIR" pull -p || return
}

function action_install_packages() {
  local _package
  show_banner "RetroPie Packages Installation"

  # install packages from binary
  for _package in "${PACKAGES_BINARY[@]}"; do
    show_message "Installing '%s' package from binary ..." "$_package"
    install_package_from_binary "$_package" || return
  done

  # install packages from source
  for _package in "${PACKAGES_SOURCE[@]}"; do
    show_message "Installing '%s' package from source ..." "$_package"
    install_package_from_source "$_package" || return
  done
}

function action_configure_retropie() {
  show_banner "RetroPie Configuration"

  # configure GPU memory split and overscan scale
  show_message "Configuring GPU memory split and overscan scale ..."
  set_rpiconfig_option "gpu_mem_256" "128" || return
  set_rpiconfig_option "gpu_mem_512" "256" || return
  set_rpiconfig_option "gpu_mem_1024" "256" || return
  set_rpiconfig_option "overscan_scale" "1" || return

  # enable required kernel modules
  show_message "Enabling required kernel modules ..."
  run_retropie_packages "raspbiantools" "enable_modules" || return

  # enable splashscreen
  show_message "Enabling splashscreen ..."
  run_retropie_packages "splashscreen" "default" || return
  run_retropie_packages "splashscreen" "enable" || return

  # enable autostart
  show_message "Enabling autostart ..."
  run_retropie_packages "autostart" "enable" || return
}

function action_configure_bluetooth() {
  local _adapter
  local _device
  show_banner "Bluetooth Configuration"
  ! have_bluetooth && return

  # install required apt packages
  show_message "Installing required APT packages ..."
  install_apt_packages bluetooth bluez bluez-firmware libbluetooth3 || return

  # install bluetooth dependencies
  show_message "Installing bluetooth dependencies ..."
  run_retropie_packages "bluetooth" "depends" || return

  # stop bluetooth service
  show_message "Stopping bluetooth service ..."
  run_systemctl "stop" "bluetooth" || return

  # configure bluetooth devices
  for _adapter in $(get_bluetooth_adapters); do
    for _device in "${!BLUETOOTH_DEVICE_INFO[@]}"; do
      show_message "Configuring adapter '%s' with device '%s' ..." \
        "$_adapter" "$_device"
      write_bluetooth_info "$_adapter" "$_device" \
        "${BLUETOOTH_DEVICE_INFO[$_device]}" || return
      write_bluetooth_cache "$_adapter" "$_device" \
        "${BLUETOOTH_DEVICE_CACHE[$_device]}" || return
    done
  done

  # start bluetooth service
  show_message "Starting bluetooth service ..."
  run_systemctl "start" "bluetooth" || return
}

function action_configure_emulators() {
  local _system
  local _filename
  show_banner "Default Emulators Configuration"

  # configure default emulator for each system
  for _system in "${!EMULATOR[@]}"; do
    show_message "Configuring '%s' system ..." "$_system"
    _filename=$(print "$EMULATORS_FILE" "$_system")
    if [[ -f $_filename ]]; then
      sed -E "/^default ?=/d" -i "$_filename" || return
    fi
    println "default = \"%s\"" "${EMULATOR[$_system]}" \
      >> "$_filename" || return
  done
}

function action_configure_videomodes() {
  local _emulator
  show_banner "Default Video Modes Configuration"

  # configure video mode for each emulator
  for _emulator in "${!VIDEO_MODE[@]}"; do
    show_message "Configuring '%s' emulator ..." "$_emulator"
    if [[ -f $VIDEO_MODES_FILE ]]; then
      sed -E "/^$_emulator ?=/d" -i "$VIDEO_MODES_FILE" || return
    fi
    println "%s = \"%s\"" "$_emulator" "${VIDEO_MODE[$_emulator]}" \
      >> "$VIDEO_MODES_FILE" || return
  done
}

function action_configure_shaders() {
  local _core_name
  local _shader_type
  show_banner "Retroarch Video Shaders Configuration"

  # enable video shader option
  show_message "Enabling video shader option in retroarch ..."
  set_retroarch_option "video_shader_enable" "true" || return

  # configure video shaders
  for _core_name in "${!SHADER_PRESET_TYPE[@]}"; do
    show_message "Configuring core name '%s' ..." "$_core_name"
    _shader_type=${SHADER_PRESET_TYPE[$_core_name]}
    write_shader_preset "$_core_name" \
      "${SHADER_PRESET[$_shader_type]}" || return
  done
}

function action_configure_joypads() {
  local _joypad
  local _player
  local _system_core_name
  show_banner "Retroarch Joypads Configuration"

  # configure joypad autoconfigs
  for _joypad in "${!JOYPAD_AUTOCONFIG[@]}"; do
    show_message "Configuring autoconfig for joypad '%s' ..." "$_joypad"
    write_joypad_autoconfig "$_joypad" \
      "${JOYPAD_AUTOCONFIG[$_joypad]}" || return
  done

  # configure joypad indices
  for _player in "${!JOYPAD_INDEX[@]}"; do
    show_message "Configuring joypad index for player '%s' ..." "$_player"
    set_retroarch_option "input_player${_player}_joypad_index" \
      "${JOYPAD_INDEX[$_player]}" || return
  done

  # configure joypad remaps
  for _system_core_name in "${!JOYPAD_REMAP[@]}"; do
    show_message "Configuring joypad remap for system/core name '%s' ..." \
      "$_system_core_name"
    write_joypad_remap "${_system_core_name%/*}" "${_system_core_name#*/}" \
      "${JOYPAD_REMAP[$_system_core_name]}" || return
  done
}

function action_configure_es() {
  show_banner "EmulationStation Configuration"

  # configure controller input
  show_message "Configuring controller input ..."
  if [[ -n $ES_INPUT ]]; then
    cat > "$ES_INPUT_FILE" <<<"$ES_INPUT" || return
  fi

  # configure settings
  show_message "Configuring settings ..."
  if [[ -n $ES_SETTINGS ]]; then
    cat > "$ES_SETTINGS_FILE" <<<"$ES_SETTINGS" || return
  fi
}

function action_configure_quietmode() {
  show_banner "Quiet Mode Configuration"

  # enable hush login
  show_message "Enabling hush login ..."
  touch "$HOME"/.hushlogin || return

  # enable skip-login in autologin
  show_message "Enabling skip-login in autologin ..."
  enable_autologin_skip_login || return
  run_systemctl "daemon-reload" || return

  # disable boot rainbow splash screen
  show_message "Disabling boot rainbow splash screen ..."
  set_rpiconfig_option "disable_splash" "1" || return

  # configure kernel cmdline for quiet boot
  show_message "Configuring kernel cmdline ..."
  configure_kcmdline || return
}

function action_configure_dtoverlays() {
  local _dtoverlay
  show_banner "Device-Tree Overlays Configuration"

  # configure dt overlay and parameters
  for _dtoverlay in "${!DTOVERLAY[@]}"; do
    show_message "Configuring DT overlay '%s' ..." "$_dtoverlay"
    set_rpiconfig_dtoverlay "$_dtoverlay" \
      "${DTOVERLAY[$_dtoverlay]}" || return
  done
}

function action_clean() {
  show_banner "System Clean"

  # clean the APT system
  show_message "Cleaning local APT package files repository ..."
  clean_apt || return
}

function action_post_upgrade_hook() {
  if [[ $(type -t my_retropie_upgrade_hook) == function ]]; then
    show_banner "Post-Upgrade Hook"
    my_retropie_upgrade_hook || return
  fi
}

function action_post_setup_hook() {
  if [[ $(type -t my_retropie_setup_hook) == function ]]; then
    show_banner "Post-Setup Hook"
    my_retropie_setup_hook || return
  fi
}

#===============================================================================
# Action dispatcher

function my_retropie() {
  show_banner "Welcome to MyRetroPie !"
  show_variables
  case $1 in
    upgrade)
      show_message "Action: UPGRADE INSTALLATION"
      confirm "Continue?" || return
      action_raspbian_update || return
      action_retropie_update || return
      action_install_packages || return
      action_clean || return
      action_post_upgrade_hook || return
      ;;
    *)
      show_message "Action: COMPLETE SETUP"
      confirm "Continue?" || return
      action_apt_setup || return
      action_raspbian_update || return
      action_raspbian_setup || return
      action_retropie_setup || return
      action_install_packages || return
      action_configure_retropie || return
      action_configure_bluetooth || return
      action_configure_emulators || return
      action_configure_videomodes || return
      action_configure_shaders || return
      action_configure_joypads || return
      action_configure_es || return
      action_configure_quietmode || return
      action_configure_dtoverlays || return
      action_clean || return
      action_post_setup_hook || return
      ;;
  esac
  show_banner "MyRetroPie finished !" && new_line
}
