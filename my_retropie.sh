#!/usr/bin/env bash
# Automated setup for my personal RetroPie installation.
# script by github.com/hhromic

################################################################################
# Configuration

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
)

# shaders preset directory
SHADER_PRESETS_DIR=/opt/retropie/configs/all/retroarch/shaders/presets

# LCD-based cores
LCD_CORES=(
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

# CRT-based cores
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

################################################################################
# Functions

function install_package_from_binary() {
    return
}

function install_package_from_source() {
    return
}

function setup_shader_preset() {
    return
}

################################################################################
# RetroPie setup

# clone the latest RetroPie-Setup repository
cd ~ || exit 1
git clone https://github.com/RetroPie/RetroPie-Setup || exit 1

# install packages from binary

# install packages from source

# set autostart to start Emulation Station at boot

################################################################################
# Video modes and shaders setup

# set "CEA-4" (for 720p) as the default video mode for the installed cores

# configure video shader for the LCD-based installed cores

################################################################################
# finishing details

# make login more silent
touch ~/.hushlogin || exit 1

# set the hostname to "retropie"
sudo bash <<"EOF" || exit 1
echo "retropie" > /etc/hostname
sed -i "s/raspberrypi/retropie/g" /etc/hosts
EOF

# do not wait for network interfaces during boot
sudo rm -f /etc/systemd/system/dhcpcd.service.d/wait.conf || exit 1

# make boot more silent
