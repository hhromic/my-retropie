#!/usr/bin/env bash
# Automated management script for custom RetroPie installations.
# script by github.com/hhromic

#===============================================================================
# Files and directories

# RetroPie base directory
RETROPIE_BASE_DIR=$HOME/RetroPie-Setup

# config files base directory
CONFIGS_BASE_DIR=/opt/retropie/configs

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

#===============================================================================
# Raspbian Configuration

# device hostname
: "${DEVICE_HOSTNAME:=retropie}"

# device timezone
: "${DEVICE_TIMEZONE:=Etc/UTC}"

#===============================================================================
# RetroPie Configuration

# RetroPie git repository URL
RETROPIE_REPOSITORY=https://github.com/RetroPie/RetroPie-Setup

# packages to be installed from binary
PACKAGES_BINARY=(
    "retroarch"
    "emulationstation"
    "runcommand"
    "splashscreen"
)

# packages to be installed from source
PACKAGES_SOURCE=(
    "lr-genesis-plus-gx"
    "lr-mgba"
    "lr-mupen64plus"
    "lr-nestopia"
    "lr-pcsx-rearmed"
    "lr-snes9x"
)

# default emulators video mode
VIDEO_MODE=CEA-4

# emulators to set default video mode for
VIDEO_MODE_EMULATORS=("${PACKAGES_SOURCE[@]}")

# LCD-based libretro cores
LCD_CORE_NAMES=(
    "mGBA"
)

# LCD-based shader preset
read -r -d "" LCD_SHADER_PRESET <<EOF
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

# CRT-based libretro cores
CRT_CORE_NAMES=(
    "Genesis Plus GX"
    "Nestopia"
    "Mupen64Plus GLES2"
    "PCSX-ReARMed"
    "Snes9x"
)

# CRT-based shader preset
read -r -d "" CRT_SHADER_PRESET <<EOF
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

#===============================================================================
# Helpers

function print {
    local _format="$1"; shift
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
    local _token
    local _code
    for _token in "$@"; do
        _code=""
        case "$_token" in
            reset)      _code="0m" ;;
            bold)       _code="1m" ;;
            underline)  _code="4m" ;;
            blink)      _code="5m" ;;
            reverse)    _code="7m" ;;
            invisible)  _code="8m" ;;
            fg_black)   _code="30m" ;;
            fg_red)     _code="31m" ;;
            fg_green)   _code="32m" ;;
            fg_yellow)  _code="33m" ;;
            fg_blue)    _code="34m" ;;
            fg_magenta) _code="35m" ;;
            fg_cyan)    _code="36m" ;;
            fg_white)   _code="37m" ;;
            bg_black)   _code="40m" ;;
            bg_red)     _code="41m" ;;
            bg_green)   _code="42m" ;;
            bg_yellow)  _code="43m" ;;
            bg_blue)    _code="44m" ;;
            bg_magenta) _code="45m" ;;
            bg_cyan)    _code="46m" ;;
            bg_white)   _code="47m" ;;
        esac
        [[ -n "$_code" ]] && print $'\e'"[%s" "$_code"
    done
}

function confirm {
    local _ans
    ansi_code reset && new_line && print "%s (" "$@" &&
    ansi_code fg_green && print "y" &&
    ansi_code reset && print "/" &&
    ansi_code fg_red && print "[N]" &&
    ansi_code reset && print ") "
    read -r _ans
    case "$_ans" in
        y*|Y*) return 0 ;;
        *) return 1 ;;
    esac
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
        local _label="$1"; shift
        ansi_code reset fg_magenta && print "%s" "$_label" &&
        ansi_code bold && print " = " &&
        ansi_code reset && println "%s " "$@"
    }
    function _quote_arr {
        local _idx=1
        while [[ $_idx -le $# ]]; do
            [[ "$_idx" -ne 1 ]] && print " "
            print $'\"'"%s"$'\"' "${!_idx}"
            ((_idx++))
        done
    }

    show_message "Files and directories" && new_line &&
    _show_var "RETROPIE_BASE_DIR    " "$RETROPIE_BASE_DIR" &&
    _show_var "CONFIGS_BASE_DIR     " "$CONFIGS_BASE_DIR" &&
    _show_var "VIDEO_MODES_FILE     " "$VIDEO_MODES_FILE" &&
    _show_var "RETROARCH_CONFIG_FILE" "$RETROARCH_CONFIG_FILE" &&
    _show_var "SHADERS_BASE_DIR     " "$SHADERS_BASE_DIR" &&
    _show_var "SHADERS_DIR          " "$SHADERS_DIR" &&
    _show_var "SHADERS_PRESETS_DIR  " "$SHADERS_PRESETS_DIR" &&

    show_message "Raspbian configuration" && new_line &&
    _show_var "DEVICE_HOSTNAME      " "$DEVICE_HOSTNAME" &&
    _show_var "DEVICE_TIMEZONE      " "$DEVICE_TIMEZONE" &&

    show_message "RetroPie configuration" && new_line &&
    _show_var "RETROPIE_REPOSITORY  " "$RETROPIE_REPOSITORY" &&
    _show_var "PACKAGES_BINARY      " "${PACKAGES_BINARY[@]}" &&
    _show_var "PACKAGES_SOURCE      " "${PACKAGES_SOURCE[@]}" &&
    _show_var "VIDEO_MODE           " "$VIDEO_MODE" &&
    _show_var "VIDEO_MODE_EMULATORS " "${VIDEO_MODE_EMULATORS[@]}" &&
    _show_var "LCD_CORE_NAMES       " "$(_quote_arr "${LCD_CORE_NAMES[@]}")" &&
    _show_var "LCD_SHADER_PRESET    " $'\n'"$LCD_SHADER_PRESET" &&
    _show_var "CRT_CORE_NAMES       " "$(_quote_arr "${CRT_CORE_NAMES[@]}")" &&
    _show_var "CRT_SHADER_PRESET    " $'\n'"$CRT_SHADER_PRESET"
}

#===============================================================================
# Actions helpers

function update_apt_packages {
    sudo bash <<"EOF"
apt-get -y update
apt-get -y dist-upgrade
EOF
}

function set_hostname { # adapted from raspi-config
    local _hostname="$1"
    local _current_hostname
    _current_hostname=$(tr -d $'\t'$'\n'$'\r' < /etc/hostname)
    sudo bash <<EOF
echo "$_hostname" > /etc/hostname || exit
sed -e "s/127.0.1.1.*$_current_hostname/127.0.1.1\\t$_hostname/g" \
    -i /etc/hosts || exit
EOF
}

function set_timezone { # adapted from raspi-config
    local _timezone="$1"
    sudo bash <<EOF
rm -f /etc/localtime || exit
echo "$_timezone" > /etc/timezone || exit
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

function run_retropie_packages {
    sudo "$RETROPIE_BASE_DIR"/retropie_packages.sh "$@"
}

function install_package_from_binary {
    local _package="$1"
    local _action
    for _action in depends install_bin configure; do
        run_retropie_packages "$_package" "$_action" || return
    done
}

function install_package_from_source {
    local _package="$1"
    run_retropie_packages "$_package" clean || return
    run_retropie_packages "$_package" || return
}

function write_shader_preset {
    local _core_name="$1"
    local _preset="$2"
    local _base_dir="$SHADERS_PRESETS_DIR"/"$_core_name"
    mkdir -p "$_base_dir" || return
    echo "$_preset" > "$_base_dir"/"$_core_name".glslp || return
}

function disable_splash {
    sudo bash <<"EOF"
if ! grep -q "^disable_splash=" /boot/config.txt 2>/dev/null; then
    echo "disable_splash=1" >> /boot/config.txt || exit
fi
EOF
}

function configure_kcmdline {
    sudo bash <<"EOF"
function _set_var {
    local _name="$1"; local _value="$2"
    local _idx=0; local _found
    [[ -n "$_value" ]] && _value="=$_value"
    while [[ $_idx -lt ${#CMDLINE[@]} ]]; do
        if [[ "${CMDLINE[$_idx]}" =~ ^$_name(=|$) ]]; then
            CMDLINE[$_idx]="$_name$_value"
            _found=yes
        fi
        ((_idx++))
    done
    [[ -z "$_found" ]] && CMDLINE[$_idx]="$_name$_value"
}
mapfile -t CMDLINE < <(tr " " $'\n' < /boot/cmdline.txt)
_set_var "console" "tty3"
_set_var "logo.nologo"
_set_var "quiet"
_set_var "loglevel" "3"
_set_var "vt.global_cursor_default" "0"
_set_var "plymouth.enable" "0"
tr " " $'\n' <<< "${CMDLINE[@]}" | sort -u | xargs > /boot/cmdline.txt
EOF
}

function clean_apt {
    sudo bash <<"EOF"
apt-get -y clean
EOF
}

#===============================================================================
# Actions

function action_raspbian_update {
    show_banner "Raspbian Update"

    # update apt packages
    show_message "Updating APT packages ..."
    update_apt_packages || return
}

function action_raspbian_setup {
    show_banner "Raspbian Setup"

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

function action_retropie_setup {
    show_banner "RetroPie Setup"

    # clone RetroPie-Setup repository
    show_message "Cloning Retropie-Setup into '%s' ..." "$RETROPIE_BASE_DIR"
    git clone "$RETROPIE_REPOSITORY" "$RETROPIE_BASE_DIR" || return
}

function action_install_packages {
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

function action_configure_retropie {
    show_banner "RetroPie Configuration"

    # get bluetooth depends
    show_message "Getting bluetooth depends ..."
    run_retropie_packages bluetooth depends || return

    # enable required kernel modules
    show_message "Enabling required kernel modules ..."
    run_retropie_packages raspbiantools enable_modules || return

    # enable splashscreen
    show_message "Enabling splashscreen ..."
    run_retropie_packages splashscreen default || return
    run_retropie_packages splashscreen enable || return

    # enable autostart
    show_message "Enabling autostart ..."
    run_retropie_packages autostart enable || return
}

function action_configure_videomode {
    local _emulator
    show_banner "Emulators Video Mode Configuration"
    :> "$VIDEO_MODES_FILE" || return
    for _emulator in "${VIDEO_MODE_EMULATORS[@]}"; do
        show_message "Configuring '%s' emulator ..." "$_emulator"
        echo "$_emulator = \"$VIDEO_MODE\"" >> "$VIDEO_MODES_FILE" || return
    done
}

function action_configure_shaders {
    local _core_name
    show_banner "Retroarch Video Shaders Configuration"

    # enable video shader option
    show_message "Enabling video shader option in retroarch ..."
    sed -e 's/^.*video_shader_enable.*$/video_shader_enable = true/g' \
        -i "$RETROARCH_CONFIG_FILE" || return

    # configure video shader for LCD-based cores
    for _core_name in "${LCD_CORE_NAMES[@]}"; do
        show_message "Configuring libretro core '%s' for LCD ..." "$_core_name"
        write_shader_preset "$_core_name" "$LCD_SHADER_PRESET" || return
    done

    # configure video shader for CRT-based cores
    for _core_name in "${CRT_CORE_NAMES[@]}"; do
        show_message "Configuring libretro core '%s' for CRT ..." "$_core_name"
        write_shader_preset "$_core_name" "$CRT_SHADER_PRESET" || return
    done
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

function my_retropie_start {
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
            action_raspbian_update || return
            action_raspbian_setup || return
            action_retropie_setup || return
            action_install_packages || return
            action_configure_retropie || return
            action_configure_videomode || return
            action_configure_shaders || return
            action_configure_quietmode || return
            action_clean || return
            ;;
    esac
    show_banner "MyRetroPie finished !" && new_line
}
