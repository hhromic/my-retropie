# My RetroPie Setup Guide

This is my personal guide for setting up a current version of RetroPie.

All the instructions below are meant to be run as the normal user `pi`.

## Instructions

1. Download the latest version of Raspbian Stretch Nano from <https://github.com/hhromic/pi-gen-nano/releases/latest>

2. Copy the downloaded image to an SD Card

3. Create the `/boot/ssh` and `/boot/wpa_supplicant.conf` files in the SD Card

4. Boot the Raspberry Pi device and login either via SSH or the console

5. Install the `wget` package for downloading the scripts:

       sudo apt-get install wget

6. Start the personal installation script:

       bash <(wget https://git.io/fAeSi -qO-)

