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

# controller mappings for retroarch joypads
JOYPAD_MAPPING=(
  ["PLAYSTATION(R)3 Controller"]="$(cat <<"EOF"
input_device = "PLAYSTATION(R)3 Controller"
input_driver = "udev"
input_r_y_plus_axis = "+3"
input_r_x_minus_axis = "-2"
input_l_btn = "10"
input_load_state_btn = "10"
input_start_btn = "3"
input_exit_emulator_btn = "3"
input_r_y_minus_axis = "-3"
input_down_btn = "6"
input_l_x_plus_axis = "+0"
input_r_btn = "11"
input_save_state_btn = "11"
input_right_btn = "5"
input_state_slot_increase_btn = "5"
input_select_btn = "0"
input_left_btn = "7"
input_state_slot_decrease_btn = "7"
input_l2_btn = "8"
input_l3_btn = "1"
input_l_y_minus_axis = "-1"
input_up_btn = "4"
input_a_btn = "13"
input_b_btn = "14"
input_reset_btn = "14"
input_enable_hotkey_btn = "16"
input_l_y_plus_axis = "+1"
input_r2_btn = "9"
input_r3_btn = "2"
input_x_btn = "12"
input_menu_toggle_btn = "12"
input_l_x_minus_axis = "-0"
input_y_btn = "15"
input_r_x_plus_axis = "+2"
EOF
)"
  ["szmy-power Ltd.  Joypad  "]="$(cat <<"EOF"
input_device = "szmy-power Ltd.  Joypad  "
input_driver = "udev"
input_r_y_plus_axis = "+3"
input_r_x_minus_axis = "-2"
input_l_btn = "8"
input_load_state_btn = "8"
input_start_btn = "11"
input_exit_emulator_btn = "11"
input_r_y_minus_axis = "-3"
input_down_btn = "h0down"
input_l_x_plus_axis = "+0"
input_r_btn = "9"
input_save_state_btn = "9"
input_right_btn = "h0right"
input_state_slot_increase_btn = "h0right"
input_select_btn = "10"
input_left_btn = "h0left"
input_state_slot_decrease_btn = "h0left"
input_l2_btn = "6"
input_l3_btn = "13"
input_l_y_minus_axis = "-1"
input_up_btn = "h0up"
input_a_btn = "0"
input_b_btn = "1"
input_reset_btn = "1"
input_enable_hotkey_btn = "2"
input_l_y_plus_axis = "+1"
input_r2_btn = "7"
input_r3_btn = "14"
input_x_btn = "3"
input_menu_toggle_btn = "3"
input_l_x_minus_axis = "-0"
input_y_btn = "4"
input_r_x_plus_axis = "+2"
EOF
)"
)

# joypad indices for retroarch players
JOYPAD_INDEX=([1]=1 [2]=0)

# emulationstation input config
read -r -d "" ES_INPUT <<"EOF"
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
  <inputConfig type="joystick" deviceName="PLAYSTATION(R)3 Controller" deviceGUID="060000004c0500006802000000010000">
    <input name="pageup" type="button" id="10" value="1"/>
    <input name="start" type="button" id="3" value="1"/>
    <input name="down" type="button" id="6" value="1"/>
    <input name="pagedown" type="button" id="11" value="1"/>
    <input name="right" type="button" id="5" value="1"/>
    <input name="select" type="button" id="0" value="1"/>
    <input name="left" type="button" id="7" value="1"/>
    <input name="up" type="button" id="4" value="1"/>
    <input name="a" type="button" id="13" value="1"/>
    <input name="b" type="button" id="14" value="1"/>
    <input name="x" type="button" id="12" value="1"/>
    <input name="y" type="button" id="15" value="1"/>
  </inputConfig>
  <inputConfig type="joystick" deviceName="szmy-power Ltd.  Joypad  " deviceGUID="05000000c82d00002038000000010000">
    <input name="pageup" type="button" id="6" value="1"/>
    <input name="start" type="button" id="11" value="1"/>
    <input name="down" type="hat" id="0" value="4"/>
    <input name="pagedown" type="button" id="7" value="1"/>
    <input name="right" type="hat" id="0" value="2"/>
    <input name="select" type="button" id="10" value="1"/>
    <input name="left" type="hat" id="0" value="8"/>
    <input name="up" type="hat" id="0" value="1"/>
    <input name="a" type="button" id="0" value="1"/>
    <input name="b" type="button" id="1" value="1"/>
    <input name="x" type="button" id="3" value="1"/>
    <input name="y" type="button" id="4" value="1"/>
  </inputConfig>
</inputList>
EOF

#===============================================================================
# Run MyRetropie

my_retropie "$@" || exit
