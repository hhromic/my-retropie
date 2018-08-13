#!/usr/bin/env bash
# Automated setup for my personal RetroPie installation.
# script by github.com/hhromic

#===============================================================================
# Configuration

# device hostname
HOSTNAME="retropie"

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

# video modes config file
VIDEO_MODES_FILE=/opt/retropie/configs/all/videomodes.cfg

# default video mode for emulators
VIDEO_MODE="CEA-4"

# emulators to set default video mode for
VIDEO_MODE_EMULATORS=("${PACKAGES_SOURCE[@]}")

# retroarch config file
RETROARCH_CONFIG_FILE=/opt/retropie/configs/all/retroarch.cfg

# shaders preset directory
SHADER_PRESETS_DIR=/opt/retropie/configs/all/retroarch/shaders/presets

# LCD-based libretro cores
LCD_CORE_NAMES=(
    "mGBA"
)

# LCD-based shader preset
read -r -d "" LCD_SHADER_PRESET <<"EOF"
shaders = "1"
shader0 = "/home/pi/.config/retroarch/shaders/shaders/zfast_lcd_standard.glsl"
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
read -r -d "" CRT_SHADER_PRESET <<"EOF"
shaders = "1"
shader0 = "/home/pi/.config/retroarch/shaders/shaders/zfast_crt_standard.glsl"
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
# Functions

function install_package_from_binary() {
    local package="$1"
    local action
    for action in depends install_bin configure; do
        sudo ~/RetroPie-Setup/retropie_packages.sh \
            "$package" "$action" || return
    done
}

function install_package_from_source() {
    local package="$1"
    sudo ~/RetroPie-Setup/retropie_packages.sh "$package" clean || return
    sudo ~/RetroPie-Setup/retropie_packages.sh "$package"
}

function setup_shader_preset() {
    local core_name="$1"
    local preset="$2"
    local base_dir="$SHADER_PRESETS_DIR"/"$core_name"
    mkdir -p "$base_dir" || return
    echo "$preset" > "$base_dir"/"$core_name".glslp
}

#===============================================================================
# Welcome message

echo
echo "** Welcome to the MyRetroPie automated installation script **"
echo

#===============================================================================
# RetroPie setup

# clone latest RetroPie-Setup repository
echo "cloning latest Retropie-Setup repository ..."
git clone https://github.com/RetroPie/RetroPie-Setup ~/RetroPie-Setup || exit 1

# install packages from binary
echo "installing packages from binary ..."
for package in "${PACKAGES_BINARY[@]}"; do
    echo "package: $package"
    install_package_from_binary "$package" || exit 1
done

# install packages from source
echo "installing packages from source ..."
for package in "${PACKAGES_SOURCE[@]}"; do
    echo "package: $package"
    install_package_from_source "$package" || exit 1
done

# set autostart to start Emulation Station at boot

#===============================================================================
# Video modes and shaders setup

# set default video mode for emulators
echo "setting default video mode for emulators ..."
:> "$VIDEO_MODES_FILE" || exit 1
for emulator in "${VIDEO_MODE_EMULATORS[@]}"; do
    echo "* emulator: $emulator"
    echo "$emulator = \"$VIDEO_MODE\"" >> "$VIDEO_MODES_FILE" || exit 1
done

# enable video shader option
echo "enabling video shader option ..."
sed -i 's/^.*video_shader_enable.*$/video_shader_enable = true/g' \
    "$RETROARCH_CONFIG_FILE"

# configure video shader for LCD-based cores
echo "configuring video shader for LCD-based cores ..."
for core_name in "${LCD_CORE_NAMES[@]}"; do
    echo "* libretro core name: $core_name"
    setup_shader_preset "$core_name" "$LCD_SHADER_PRESET" || exit 1
done

# configure video shader for CRT-based cores
echo "configuring video shader for CRT-based cores ..."
for core_name in "${CRT_CORE_NAMES[@]}"; do
    echo "* libretro core name: $core_name"
    setup_shader_preset "$core_name" "$CRT_SHADER_PRESET" || exit 1
done

#===============================================================================
# finishing details

# set device hostname
echo "setting device hostname ..."
sudo bash <<EOF || exit 1
echo "$HOSTNAME" > /etc/hostname
sed -i "s/raspberrypi/$HOSTNAME/g" /etc/hosts
EOF

# enable hush login
echo "enabling hush login ..."
touch ~/.hushlogin || exit 1

# disable network wait during boot
echo "disabling network wait during boot ..."
sudo bash <<"EOF" || exit 1
[[ -f /etc/systemd/system/dhcpcd.service.d/wait.conf ]] &&
sudo rm -f /etc/systemd/system/dhcpcd.service.d/wait.conf
EOF

# configure kernel cmdline for quiet boot [TODO]
echo "configuring kernel cmdline for quiet boot ..."

# disable boot rainbow splash screen
echo "disabling boot rainbow splash screen ..."
sudo bash <<"EOF" || exit 1
if ! grep -q "^disable_splash=" /boot/config.txt 2>/dev/null; then
    echo "disable_splash=1" >> /boot/config.txt
fi
EOF
