#!/usr/bin/env bash
# Automated management script for my personal RetroPie installation.
# script by github.com/hhromic

#===============================================================================
# Files and directories

# RetroPie base directory
: "${RETROPIE_BASE_DIR:=$HOME/RetroPie-Setup}"

# config files base directory
: "${CONFIGS_BASE_DIR:=/opt/retropie/configs}"

# video modes config file
: "${VIDEO_MODES_FILE:=$CONFIGS_BASE_DIR/all/videomodes.cfg}"

# retroarch config file
: "${RETROARCH_CONFIG_FILE:=$CONFIGS_BASE_DIR/all/retroarch.cfg}"

# shaders base directory
: "${SHADERS_BASE_DIR:=$CONFIGS_BASE_DIR/all/retroarch/shaders}"

# shaders directory
: "${SHADERS_DIR:=$SHADERS_BASE_DIR/shaders}"

# shaders presets directory
: "${SHADERS_PRESETS_DIR:=$SHADERS_BASE_DIR/presets}"

#===============================================================================
# Raspbian Configuration

# device hostname
: "${DEVICE_HOSTNAME:=retropie}"

# device timezone
: "${DEVICE_TIMEZONE:=Etc/UTC}"

#===============================================================================
# RetroPie Configuration

# RetroPie git repository URL
: "${RETROPIE_REPOSITORY:=https://github.com/RetroPie/RetroPie-Setup}"

# packages to be installed from binary
[[ -z $PACKAGES_BINARY ]] &&
PACKAGES_BINARY=(
    "retroarch"
    "emulationstation"
    "runcommand"
    "splashscreen"
)

# packages to be installed from source
[[ -z $PACKAGES_SOURCE ]] &&
PACKAGES_SOURCE=(
    "lr-genesis-plus-gx"
    "lr-mgba"
    "lr-mupen64plus"
    "lr-nestopia"
    "lr-pcsx-rearmed"
    "lr-snes9x"
)

# default emulators video mode
: "${VIDEO_MODE:=CEA-4}"

# emulators to set default video mode for
[[ -z $VIDEO_MODE_EMULATORS ]] &&
VIDEO_MODE_EMULATORS=("${PACKAGES_SOURCE[@]}")

# LCD-based libretro cores
[[ -z $LCD_CORE_NAMES ]] &&
LCD_CORE_NAMES=(
    "mGBA"
)

# LCD-based shader preset
[[ -z $LCD_SHADER_PRESET ]] &&
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
[[ -z $CRT_CORE_NAMES ]] &&
CRT_CORE_NAMES=(
    "Genesis Plus GX"
    "Nestopia"
    "Mupen64Plus GLES2"
    "PCSX-ReARMed"
    "Snes9x"
)

# CRT-based shader preset
[[ -z $CRT_SHADER_PRESET ]] &&
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
    local format="$1"; shift
    # shellcheck disable=SC2059
    printf "$format" "$@"
}

function new_line {
    print "%s" $'\n'
}

function println {
    print "$@" && new_line
}

function ansi_code {
    local token
    local code
    for token in "$@"; do
        code=""
        case "$token" in
            reset)      code="0m" ;;
            bold)       code="1m" ;;
            underline)  code="4m" ;;
            blink)      code="5m" ;;
            reverse)    code="7m" ;;
            invisible)  code="8m" ;;
            fg_black)   code="30m" ;;
            fg_red)     code="31m" ;;
            fg_green)   code="32m" ;;
            fg_yellow)  code="33m" ;;
            fg_blue)    code="34m" ;;
            fg_magenta) code="35m" ;;
            fg_cyan)    code="36m" ;;
            fg_white)   code="37m" ;;
            bg_black)   code="40m" ;;
            bg_red)     code="41m" ;;
            bg_green)   code="42m" ;;
            bg_yellow)  code="43m" ;;
            bg_blue)    code="44m" ;;
            bg_magenta) code="45m" ;;
            bg_cyan)    code="46m" ;;
            bg_white)   code="47m" ;;
        esac
        [[ -n "$code" ]] && print $'\e'"[%s" "$code"
    done
}

function confirm() {
    local ans
    ansi_code reset && new_line && print "%s (" "$@" &&
    ansi_code fg_green && print "y" &&
    ansi_code reset && print "/" &&
    ansi_code fg_red && print "[N]" &&
    ansi_code reset && print ") "
    read -r ans
    case "$ans" in
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
        ansi_code reset &&
        ansi_code fg_magenta && print "%s" "$_label" &&
        ansi_code bold && print " = " &&
        ansi_code reset && println "%s " "$@"
    }
    function _quote_arr {
        local _idx
        for _idx in $(seq "$#"); do
            [[ "$_idx" -ne 1 ]] && print " "
            print $'\"'"%s"$'\"' "${!_idx}"
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

function update_raspbian {
    sudo bash <<"EOF"
apt-get -y update
apt-get -y dist-upgrade
EOF
}

function set_hostname { # [TODO:IMPROVE]
    local hostname="$1"
    sudo bash <<EOF
echo "$hostname" > /etc/hostname || exit
sed -i "s/raspberrypi/$hostname/g" /etc/hosts
EOF
}

function set_timezone { # [TODO:TEST:IMPROVE]
    local timezone="$1"
    sudo bash <<EOF
echo "$timezone" > /etc/timezone || exit
dpkg-reconfigure -f noninteractive tzdata
EOF
}

function disable_network_wait {
    sudo bash <<"EOF"
if [[ -f /etc/systemd/system/dhcpcd.service.d/wait.conf ]]; then
    rm -f /etc/systemd/system/dhcpcd.service.d/wait.conf || exit
fi
EOF
}

function call_retropie_packages {
    sudo "$RETROPIE_BASE_DIR"/retropie_packages.sh "$@"
}

function install_package_from_binary() {
    local package="$1"
    local action
    for action in depends install_bin configure; do
        call_retropie_packages "$package" "$action" || return
    done
}

function install_package_from_source() {
    local package="$1"
    call_retropie_packages "$package" clean || return
    call_retropie_packages "$package" || return
}

function write_shader_preset() {
    local core_name="$1"
    local preset="$2"
    local base_dir="$SHADERS_PRESETS_DIR"/"$core_name"
    mkdir -p "$base_dir" || return
    echo "$preset" > "$base_dir"/"$core_name".glslp || return
}

function disable_splash {
    sudo bash <<"EOF"
if ! grep -q "^disable_splash=" /boot/config.txt 2>/dev/null; then
    echo "disable_splash=1" >> /boot/config.txt || exit
fi
EOF
}

function configure_kcmdline { # [TODO:IMPROVE]
    sudo bash <<"EOF"
function _ensure_variable() {
    local name="$1"
    local value="$2"
    [[ -n "$value" ]] && value="=$value"
    if ! tr " " "\n" < /boot/cmdline.txt | grep -q "^$name=\?"; then
        sed -i "s/$/ $name$value/g" /boot/cmdline.txt || return
    else
        sed -i "s/$name=\?\S*/$name$value/g" /boot/cmdline.txt || return
    fi
}
_ensure_variable "console" "tty3" || exit
_ensure_variable "logo.nologo" || exit
_ensure_variable "quiet" || exit
_ensure_variable "loglevel" "3" || exit
_ensure_variable "vt.global_cursor_default" "0" || exit
_ensure_variable "plymouth.enable" "0" || exit
EOF
}

#===============================================================================
# Actions

function action_raspbian_setup {
    show_banner "Raspbian Setup"

    # update raspbian
    show_message "Updating Raspbian ..."
    update_raspbian || return

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
    local package
    show_banner "RetroPie Packages Installation"

    # install packages from binary
    for package in "${PACKAGES_BINARY[@]}"; do
        show_message "Installing '%s' package from binary ..." "$package"
        install_package_from_binary "$package" || return
    done

    # install packages from source
    for package in "${PACKAGES_SOURCE[@]}"; do
        show_message "Installing '%s' package from source ..." "$package"
        install_package_from_source "$package" || return
    done
}

function action_configure_retropie {
    show_banner "RetroPie Configuration"

    # get bluetooth depends
    show_message "Getting bluetooth depends ..."
    call_retropie_packages bluetooth depends || return

    # enable splashscreen
    show_message "Enabling splashscreen ..."
    call_retropie_packages splashscreen default || return
    call_retropie_packages splashscreen enable || return

    # enable autostart
    show_message "Enabling autostart ..."
    call_retropie_packages autostart enable || return
}

function action_configure_videomode { # [TODO:IMPROVE]
    local emulator
    show_banner "Emulators Video Mode Configuration"
    :> "$VIDEO_MODES_FILE" || return
    for emulator in "${VIDEO_MODE_EMULATORS[@]}"; do
        show_message "Configuring '%s' emulator ..." "$emulator"
        echo "$emulator = \"$VIDEO_MODE\"" >> "$VIDEO_MODES_FILE" || return
    done
}

function action_configure_shaders { # [TODO:IMPROVE]
    local core_name
    show_banner "Retroarch Video Shaders Configuration"

    # enable video shader option
    show_message "Enabling video shader option in retroarch ..."
    sed -i 's/^.*video_shader_enable.*$/video_shader_enable = true/g' \
        "$RETROARCH_CONFIG_FILE" || return

    # configure video shader for LCD-based cores
    for core_name in "${LCD_CORE_NAMES[@]}"; do
        show_message "Configuring LCD-based libretro core '%s' ..." "$core_name"
        write_shader_preset "$core_name" "$LCD_SHADER_PRESET" || return
    done

    # configure video shader for CRT-based cores
    for core_name in "${CRT_CORE_NAMES[@]}"; do
        show_message "Configuring CRT-based libretro core '%s' ..." "$core_name"
        write_shader_preset "$core_name" "$CRT_SHADER_PRESET" || return
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

#===============================================================================
# Action dispatcher

show_banner "Welcome to MyRetroPie !"
show_variables

case "$1" in
    update)
        show_message "Action: UPDATE PACKAGES"
        confirm "Continue?" || exit
        action_install_packages || exit
        ;;
    *)
        show_message "Action: COMPLETE SETUP"
        confirm "Continue?" || exit
        action_raspbian_setup || exit
        action_retropie_setup || exit
        action_install_packages || exit
        action_configure_retropie || exit
        action_configure_videomode || exit
        action_configure_shaders || exit
        action_configure_quietmode || exit
        ;;
esac

show_banner "MyRetroPie finished !" && new_line
