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
# Start MyRetropie

my_retropie_start "$@"
