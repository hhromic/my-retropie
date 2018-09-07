#!/usr/bin/env bash
# Automated management script for custom RetroPie installations.
# script by github.com/hhromic

#===============================================================================
# Files and directories

# bluez storage directory
BLUEZ_STORAGE_DIR=/var/lib/bluetooth

# bluez device info file
BLUEZ_INFO_FILE=$BLUEZ_STORAGE_DIR/%s/%s/info

# bluez device cache file
BLUEZ_CACHE_FILE=$BLUEZ_STORAGE_DIR/%s/cache/%s

# RetroPie base directory
RETROPIE_BASE_DIR=$HOME/RetroPie-Setup

# config files base directory
CONFIGS_BASE_DIR=/opt/retropie/configs

# emulators config file
EMULATORS_FILE=$CONFIGS_BASE_DIR/%s/emulators.cfg

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

# retroarch joypads directory
JOYPADS_DIR=$CONFIGS_BASE_DIR/all/retroarch-joypads

# emulationstation input config file
ES_INPUT_FILE=$HOME/.emulationstation/es_input.cfg

#===============================================================================
# Raspbian Configuration

# device hostname
DEVICE_HOSTNAME=retropie

# device timezone
DEVICE_TIMEZONE=Etc/UTC

# info data for bluetooth devices
declare -A BLUETOOTH_DEVICE_INFO
BLUETOOTH_DEVICE_INFO=()

# cache data for bluetooth devices
declare -A BLUETOOTH_DEVICE_CACHE
BLUETOOTH_DEVICE_CACHE=()

#===============================================================================
# RetroPie Configuration

# RetroPie git repository URL
RETROPIE_REPOSITORY=https://github.com/RetroPie/RetroPie-Setup

# packages to be installed from binary
PACKAGES_BINARY=(
  retroarch
  emulationstation
  runcommand
  splashscreen
)

# packages to be installed from source
PACKAGES_SOURCE=(
  lr-genesis-plus-gx
  lr-mgba
  lr-mupen64plus
  lr-nestopia
  lr-pcsx-rearmed
  lr-snes9x
)

# default emulators for systems
declare -A EMULATOR
EMULATOR=(
  [fds]=lr-nestopia
  [gamegear]=lr-genesis-plus-gx
  [gb]=lr-mgba
  [gba]=lr-mgba
  [gbc]=lr-mgba
  [mastersystem]=lr-genesis-plus-gx
  [megadrive]=lr-genesis-plus-gx
  [n64]=lr-mupen64plus
  [nes]=lr-nestopia
  [psx]=lr-pcsx-rearmed
  [segacd]=lr-genesis-plus-gx
  [sg-1000]=lr-genesis-plus-gx
  [snes]=lr-snes9x
)

# default video modes for emulators
declare -A VIDEO_MODE
VIDEO_MODE=(
  [lr-genesis-plus-gx]=CEA-4
  [lr-mgba]=CEA-4
  [lr-mupen64plus]=CEA-4
  [lr-nestopia]=CEA-4
  [lr-pcsx-rearmed]=CEA-4
  [lr-snes9x]=CEA-4
)

# shader preset types for libretro core names
declare -A SHADER_PRESET_TYPE
SHADER_PRESET_TYPE=(
  ["mGBA"]=LCD
  ["Genesis Plus GX"]=CRT
  ["Nestopia"]=CRT
  ["Mupen64Plus GLES2"]=CRT
  ["PCSX-ReARMed"]=CRT
  ["Snes9x"]=CRT
)

# shader presets for shader preset types
declare -A SHADER_PRESET
SHADER_PRESET=(
  [CRT]="$(cat <<EOF
shaders = "1"
shader0 = "$SHADERS_DIR/zfast_crt_standard.glsl"
filter_linear0 = "true"
wrap_mode0 = "clamp_to_border"
mipmap_input0 = "false"
alias0 = ""
float_framebuffer0 = "false"
srgb_framebuffer0 = "false"
parameters = "BLURSCALEX;LOWLUMSCAN;HILUMSCAN;BRIGHTBOOST;MASK_DARK;MASK_FADE"
BLURSCALEX = "0.300000"
LOWLUMSCAN = "6.000000"
HILUMSCAN = "8.000000"
BRIGHTBOOST = "1.250000"
MASK_DARK = "0.250000"
MASK_FADE = "0.800000"
EOF
)"
  [LCD]="$(cat <<EOF
shaders = "1"
shader0 = "$SHADERS_DIR/zfast_lcd_standard.glsl"
filter_linear0 = "true"
wrap_mode0 = "clamp_to_border"
mipmap_input0 = "false"
alias0 = ""
float_framebuffer0 = "false"
srgb_framebuffer0 = "false"
parameters = "BORDERMULT;GBAGAMMA"
BORDERMULT = "3.000000"
GBAGAMMA = "1.000000"
EOF
)"
)

# controller mappings for retroarch joypads
declare -A JOYPAD_MAPPING
JOYPAD_MAPPING=()

# joypad indices for retroarch players
declare -A JOYPAD_INDEX
JOYPAD_INDEX=()

# emulationstation input config
read -r -d "" ES_INPUT <<EOF
<?xml version="1.0"?>
<inputList>
  <inputAction type="onfinish">
    <command>/opt/retropie/supplementary/emulationstation/scripts/inputconfiguration.sh</command>
  </inputAction>
  <inputConfig type="keyboard" deviceName="Keyboard" deviceGUID="-1">
    <input name="pageup" type="key" id="113" value="1"/>
    <input name="start" type="key" id="13" value="1"/>
    <input name="down" type="key" id="1073741905" value="1"/>
    <input name="pagedown" type="key" id="119" value="1"/>
    <input name="right" type="key" id="1073741903" value="1"/>
    <input name="select" type="key" id="1073742053" value="1"/>
    <input name="left" type="key" id="1073741904" value="1"/>
    <input name="up" type="key" id="1073741906" value="1"/>
    <input name="a" type="key" id="115" value="1"/>
    <input name="b" type="key" id="120" value="1"/>
    <input name="x" type="key" id="97" value="1"/>
    <input name="y" type="key" id="122" value="1"/>
  </inputConfig>
</inputList>
EOF

#===============================================================================
# Helpers

function print {
  local -r _format="$1"; shift
  # shellcheck disable=SC2059
  printf "$_format" "$@"
}

function new_line {
  print "%s" $'\n'
}

function println {
  print "$@" && new_line
}

function ansi_code {
  local _token; for _token in "$@"; do
    local -i _code=-1
    case "$_token" in
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

function confirm {
  ansi_code reset && new_line && print "%s (" "$@" &&
  ansi_code fg_green && print "y" &&
  ansi_code reset && print "/" &&
  ansi_code fg_red && print "[N]" &&
  ansi_code reset && print ") "
  local _ans; read -r _ans
  case "$_ans" in
    y*|Y*) return 0 ;;
    *) return 1 ;;
  esac
}

function mkdirparents {
  local -r _filename="$1"
  local -r _umask="$2"
  ([[ -n "$_umask" ]] && umask "$_umask"; mkdir -p "${_filename%/*}")
}

function show_banner {
  ansi_code reset && new_line &&
  ansi_code bold fg_red &&
  println "= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =" &&
  ansi_code fg_yellow && println "$@" &&
  ansi_code fg_red &&
  println "= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =" &&
  ansi_code reset
}

function show_message {
  ansi_code reset && new_line &&
  ansi_code fg_cyan && print ">>> " &&
  ansi_code bold && println "$@" && ansi_code reset
}

function show_variables {
  function _show_var {
    local -r _label="$1"; shift
    ansi_code reset fg_magenta && print "%s" "$_label" &&
    ansi_code bold && print " = " &&
    ansi_code reset && println "%s " "$@"
  }
  function _show_arr {
    local -r _label="$1"
    ansi_code reset fg_magenta && print "%s" "$_label" &&
    ansi_code bold && println " = " && ansi_code reset
    local _keys; eval _keys=\(\"\$\{!"$2"\[@\]\}\"\)
    local _key; for _key in "${_keys[@]}"; do
      local _value; eval _value=\"\$\{"$2"\[\"\$_key\"\]\}\"
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
  _show_var "VIDEO_MODES_FILE      " "$VIDEO_MODES_FILE" &&
  _show_var "RETROARCH_CONFIG_FILE " "$RETROARCH_CONFIG_FILE" &&
  _show_var "SHADERS_BASE_DIR      " "$SHADERS_BASE_DIR" &&
  _show_var "SHADERS_DIR           " "$SHADERS_DIR" &&
  _show_var "SHADERS_PRESETS_DIR   " "$SHADERS_PRESETS_DIR" &&
  _show_var "JOYPADS_DIR           " "$JOYPADS_DIR" &&
  _show_var "ES_INPUT_FILE         " "$ES_INPUT_FILE" &&

  show_message "Raspbian configuration" && new_line &&
  _show_var "DEVICE_HOSTNAME       " "$DEVICE_HOSTNAME" &&
  _show_var "DEVICE_TIMEZONE       " "$DEVICE_TIMEZONE" &&
  _show_arr "BLUETOOTH_DEVICE_INFO " "BLUETOOTH_DEVICE_INFO" &&
  _show_arr "BLUETOOTH_DEVICE_CACHE" "BLUETOOTH_DEVICE_CACHE" &&

  show_message "RetroPie configuration" && new_line &&
  _show_var "RETROPIE_REPOSITORY   " "$RETROPIE_REPOSITORY" &&
  _show_var "PACKAGES_BINARY       " "${PACKAGES_BINARY[@]}" &&
  _show_var "PACKAGES_SOURCE       " "${PACKAGES_SOURCE[@]}" &&
  _show_arr "EMULATOR              " "EMULATOR" &&
  _show_arr "VIDEO_MODE            " "VIDEO_MODE" &&
  _show_arr "SHADER_PRESET_TYPE    " "SHADER_PRESET_TYPE" &&
  _show_arr "SHADER_PRESET         " "SHADER_PRESET" &&
  _show_arr "JOYPAD_MAPPING        " "JOYPAD_MAPPING" &&
  _show_arr "JOYPAD_INDEX          " "JOYPAD_INDEX" &&
  _show_var "ES_INPUT              " $'\n'"$ES_INPUT"
}

#===============================================================================
# Actions helpers

function enable_apt_suite {
  local -r _suite="$1"
  sudo bash <<EOF
grep "^deb" /etc/apt/sources.list | awk "{\\\$3=\"$_suite\"}1" \
  > /etc/apt/sources.list.d/"$_suite".list || exit
EOF
}

function set_apt_preference {
  local -r _filename="$1"
  local -r _package="$2"
  local -r _suite="$3"
  local -r _priority="$4"
  sudo bash <<EOF
cat > /etc/apt/preferences.d/"$_filename" <<EOF_2
Package: $_package
Pin: release a=$_suite
Pin-Priority: $_priority
EOF_2
EOF
}

function update_apt_packages {
  sudo bash <<"EOF"
apt-get -y update
apt-get -y dist-upgrade
EOF
}

function install_apt_required_packages {
  sudo bash <<"EOF"
apt-get -y install git ca-certificates \
  bluetooth bluez bluez-firmware libbluetooth3
EOF
}

function set_hostname { # adapted from raspi-config
  local -r _hostname="$1"
  local _current; _current="$(tr -d $'\t'$'\n'$'\r' < /etc/hostname)"
  sudo bash <<EOF
printf "%s"\$'\\n' "$_hostname" > /etc/hostname || exit
sed -e "s/127.0.1.1.*$_current/127.0.1.1"\$'\\t'"$_hostname/g" \
  -i /etc/hosts || exit
EOF
}

function set_timezone { # adapted from raspi-config
  local -r _timezone="$1"
  sudo bash <<EOF
rm -f /etc/localtime || exit
printf "%s"\$'\\n' "$_timezone" > /etc/timezone || exit
dpkg-reconfigure -f noninteractive tzdata || exit
EOF
}

function disable_network_wait { # adapted from raspi-config
  sudo bash <<"EOF"
if [[ -f /etc/systemd/system/dhcpcd.service.d/wait.conf ]]; then
  rm -f /etc/systemd/system/dhcpcd.service.d/wait.conf || exit
fi
EOF
}

function get_bluetooth_adapters {
  hciconfig | grep -o -E "([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}" \
    | tr "[:lower:]" "[:upper:]"
}

function write_bluetooth_info {
  local -r _adapter="$1"
  local -r _device="$2"
  local -r _data="$3"
  local _filename; _filename="$(print "$BLUEZ_INFO_FILE" "$_adapter" "$_device")"
  mkdirparents "$_filename" "0077" || return
  println "$_data" > "$_filename" || return
}

function write_bluetooth_cache {
  local -r _adapter="$1"
  local -r _device="$2"
  local -r _data="$3"
  local _filename; _filename="$(print "$BLUEZ_CACHE_FILE" "$_adapter" "$_device")"
  mkdirparents "$_filename" "0077" || return
  println "$_data" > "$_filename" || return
}

function run_retropie_packages {
  sudo "$RETROPIE_BASE_DIR"/retropie_packages.sh "$@"
}

function install_package_from_binary {
  local -r _package="$1"
  local _action; for _action in depends install_bin configure; do
    run_retropie_packages "$_package" "$_action" || return
  done
}

function install_package_from_source {
  local -r _package="$1"
  run_retropie_packages "$_package" clean || return
  run_retropie_packages "$_package" || return
}

function set_retroarch_option {
  local -r _option="$1"
  local -r _value="$2"
  sed -e "s/^.*$_option.*$/$_option = \"$_value\"/g" \
    -i "$RETROARCH_CONFIG_FILE" || return
}

function write_shader_preset {
  local -r _core_name="$1"
  local -r _preset="$2"
  local -r _base_dir="$SHADERS_PRESETS_DIR"/"$_core_name"
  mkdir -p "$_base_dir" || return
  println "$_preset" > "$_base_dir"/"$_core_name".glslp || return
}

function write_joypad_mapping {
  local -r _joypad="$1"
  local -r _mapping="$2"
  println "$_mapping" > "$JOYPADS_DIR"/"$_joypad".cfg || return
}

function disable_splash {
  sudo bash <<"EOF"
if ! grep -q "^disable_splash=" /boot/config.txt 2>/dev/null; then
  printf "%s"$'\n' "disable_splash=1" >> /boot/config.txt || exit
fi
EOF
}

function configure_kcmdline {
  sudo bash <<"EOF"
function _set_option {
  local -r _option="$1"
  local _value="$2"
  [[ -n "$_value" ]] && _value="=$_value"
  local -i _found=0
  local -i _idx=0; while [[ $_idx -lt ${#CMDLINE[@]} ]]; do
    if [[ "${CMDLINE[$_idx]}" =~ ^$_option(=|$) ]]; then
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

function clean_apt {
  sudo bash <<"EOF"
apt-get -y clean
EOF
}

#===============================================================================
# Actions

function action_apt_setup {
  show_banner "APT Setup"

  # enable testing suite
  show_message "Enabling 'testing' suite ..."
  enable_apt_suite "testing" || return

  # configure testing suite preference
  show_message "Configuring 'testing' suite preference ..."
  set_apt_preference "testing" "*" "testing" "-10"

  # configure bluez packages preference
  show_message "Configuring bluez packages preference ..."
  local -r _bluez_packages=(
    bluetooth bluez bluez-cups bluez-hcidump bluez-obexd bluez-test-scripts
    bluez-test-tools libbluetooth-dev libbluetooth3 bluez-firmware
  )
  set_apt_preference "bluez" "${_bluez_packages[*]}" "testing" "900"
}

function action_raspbian_update {
  show_banner "Raspbian Update"

  # update apt packages
  show_message "Updating APT packages ..."
  update_apt_packages || return
}

function action_raspbian_setup {
  show_banner "Raspbian Setup"

  # install required apt packages
  show_message "Installing required APT packages ..."
  install_apt_required_packages || return

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

function action_configure_bluetooth {
  show_banner "Bluetooth Configuration"

  # stop bluetooth service
  show_message "Stopping bluetooth service ..."
  systemctl stop bluetooth || return

  # configure bluetooth devices
  local _adapter; for _adapter in $(get_bluetooth_adapters); do
    local _device; for _device in "${!BLUETOOTH_DEVICE_INFO[@]}"; do
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
  systemctl start bluetooth || return
}

function action_retropie_setup {
  show_banner "RetroPie Setup"

  # clone RetroPie-Setup repository
  show_message "Cloning Retropie-Setup into '%s' ..." "$RETROPIE_BASE_DIR"
  git clone "$RETROPIE_REPOSITORY" "$RETROPIE_BASE_DIR" || return
}

function action_install_packages {
  show_banner "RetroPie Packages Installation"

  # install packages from binary
  local _package; for _package in "${PACKAGES_BINARY[@]}"; do
    show_message "Installing '%s' package from binary ..." "$_package"
    install_package_from_binary "$_package" || return
  done

  # install packages from source
  local _package; for _package in "${PACKAGES_SOURCE[@]}"; do
    show_message "Installing '%s' package from source ..." "$_package"
    install_package_from_source "$_package" || return
  done
}

function action_configure_retropie {
  show_banner "RetroPie Configuration"

  # install bluetooth dependencies
  show_message "Installing bluetooth dependencies ..."
  run_retropie_packages "bluetooth" "depends" || return

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

function action_configure_emulators {
  show_banner "Default Emulators Configuration"
  local _system; for _system in "${!EMULATOR[@]}"; do
    show_message "Configuring '%s' system ..." "$_system"
    local _filename; _filename="$(print "$EMULATORS_FILE" "$_system")"
    if [[ -f "$_filename" ]]; then
      sed -E "/^default ?=/d" -i "$_filename" || return
    fi
    println "default = \"%s\"" "${EMULATOR[$_system]}" \
      >> "$_filename" || return
  done
}

function action_configure_videomodes {
  show_banner "Default Video Modes Configuration"
  local _emulator; for _emulator in "${!VIDEO_MODE[@]}"; do
    show_message "Configuring '%s' emulator ..." "$_emulator"
    if [[ -f "$VIDEO_MODES_FILE" ]]; then
      sed -E "/^$_emulator ?=/d" -i "$VIDEO_MODES_FILE" || return
    fi
    println "%s = \"%s\"" "$_emulator" "${VIDEO_MODE[$_emulator]}" \
      >> "$VIDEO_MODES_FILE" || return
  done
}

function action_configure_shaders {
  show_banner "Retroarch Video Shaders Configuration"

  # enable video shader option
  show_message "Enabling video shader option in retroarch ..."
  set_retroarch_option "video_shader_enable" "true" || return

  # configure video shaders
  local _core_name; for _core_name in "${!SHADER_PRESET_TYPE[@]}"; do
    show_message "Configuring libretro core name '%s' ..." "$_core_name"
    local _shader_type="${SHADER_PRESET_TYPE[$_core_name]}"
    write_shader_preset "$_core_name" \
      "${SHADER_PRESET[$_shader_type]}" || return
  done
}

function action_configure_joypads {
  show_banner "Retroarch Joypads Configuration"

  # configure joypads mappings
  local _joypad; for _joypad in "${!JOYPAD_MAPPING[@]}"; do
    show_message "Configuring mapping for joypad '%s' ..." "$_joypad"
    write_joypad_mapping "$_joypad" \
      "${JOYPAD_MAPPING[$_joypad]}" || return
  done

  # configure joypad indices
  local _player; for _player in "${!JOYPAD_INDEX[@]}"; do
    show_message "Configuring joypad index for player '%s' ..." "$_player"
    set_retroarch_option "input_player${_player}_joypad_index" \
      "${JOYPAD_INDEX[$_player]}" || return
  done
}

function action_configure_es {
  show_banner "EmulationStation Configuration"

  # configure controller input
  show_message "Configuring controller input ..."
  cat > "$ES_INPUT_FILE" <<< "$ES_INPUT" || return
}

function action_configure_quietmode {
  show_banner "Quiet Mode Configuration"

  # enable hush login
  show_message "Enabling hush login ..."
  touch "$HOME"/.hushlogin || return

  # disable boot rainbow splash screen
  show_message "Disabling boot rainbow splash screen ..."
  disable_splash || return

  # configure kernel cmdline for quiet boot
  show_message "Configuring kernel cmdline ..."
  configure_kcmdline || return
}

function action_clean {
  show_banner "System Clean"

  # clean the APT system
  show_message "Cleaning local APT package files repository ..."
  clean_apt || return
}

#===============================================================================
# Action dispatcher

function my_retropie {
  show_banner "Welcome to MyRetroPie !"
  show_variables
  case "$1" in
    upgrade)
      show_message "Action: UPGRADE INSTALLATION"
      confirm "Continue?" || return
      action_raspbian_update || return
      action_install_packages || return
      action_clean || return
      ;;
    *)
      show_message "Action: COMPLETE SETUP"
      confirm "Continue?" || return
      action_apt_setup || return
      action_raspbian_update || return
      action_raspbian_setup || return
      action_configure_bluetooth || return
      action_retropie_setup || return
      action_install_packages || return
      action_configure_retropie || return
      action_configure_emulators || return
      action_configure_videomodes || return
      action_configure_shaders || return
      action_configure_joypads || return
      action_configure_es || return
      action_configure_quietmode || return
      action_clean || return
      ;;
  esac
  show_banner "MyRetroPie finished !" && new_line
}
