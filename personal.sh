#!/usr/bin/env bash
# Automation for my personal RetroPie installation.
# script by github.com/hhromic

# source MyRetropie script
source <(curl -sL https://git.io/fNFAV)

#===============================================================================
# Raspbian Configuration

DEVICE_TIMEZONE=Europe/Dublin

#===============================================================================
# RetroPie Configuration

# packages to be installed from source
PACKAGES_SOURCE+=(
    ps3controller
)

#===============================================================================
# Run MyRetropie

my_retropie "$@" || exit

#===============================================================================
# Configure Controller Order

show_message "Configuring controller order in retroarch ..."
set_retroarch_option input_player1_joypad_index 1 || exit
set_retroarch_option input_player2_joypad_index 0 || exit
