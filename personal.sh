#!/usr/bin/env bash
# Automation for my personal RetroPie installation.
# script by github.com/hhromic

#===============================================================================
# Raspbian Configuration

# device hostname
DEVICE_HOSTNAME=retropie

# device timezone
DEVICE_TIMEZONE=Europe/Dublin

#===============================================================================
# RetroPie Configuration

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
VIDEO_MODE_EMULATORS=(
    "lr-genesis-plus-gx"
    "lr-mgba"
    "lr-mupen64plus"
    "lr-nestopia"
    "lr-pcsx-rearmed"
    "lr-snes9x"
)

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
# Source MyRetropie

source <(curl -sL https://git.io/fNFAV) "$@"
