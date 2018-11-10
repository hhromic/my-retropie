#!/usr/bin/env bash
# Automation for my personal RetroPie installation.
# script by github.com/hhromic

# source MyRetropie script
source <(wget https://git.io/fNFAV -qO-)

#===============================================================================
# Raspbian Configuration

DEVICE_TIMEZONE=Europe/Dublin

# info data for bluetooth devices
BLUETOOTH_DEVICE_INFO=(
  [00:26:43:D4:2E:B4]="$(cat <<"EOF"
[General]
Name=Sony PLAYSTATION(R)3 Controller
SupportedTechnologies=BR/EDR;
Trusted=true
Blocked=false
Services=00001124-0000-1000-8000-00805f9b34fb;
Class=0x000508

[DeviceID]
Source=2
Vendor=1356
Product=616
Version=0
EOF
)"
  [E4:17:D8:C5:67:6D]="$(cat <<"EOF"
[General]
Name=8Bitdo NES30 Pro
Class=0x002508
SupportedTechnologies=BR/EDR;
Trusted=true
Blocked=false
Services=00001124-0000-1000-8000-00805f9b34fb;00001200-0000-1000-8000-00805f9b34fb;

[DeviceID]
Source=2
Vendor=11720
Product=14368
Version=256

[LinkKey]
Key=61D53A3E0A58BE1624EDD9B8DF7672EA
Type=0
PINLength=0
EOF
)"
)

# cache data for bluetooth devices
BLUETOOTH_DEVICE_CACHE=(
  [00:26:43:D4:2E:B4]="$(cat <<"EOF"
[ServiceRecords]
0x00010000=3601920900000A000100000900013503191124090004350D35061901000900113503190011090006350909656E09006A0901000900093508350619112409010009000D350F350D350619010009001335031900110901002513576972656C65737320436F6E74726F6C6C65720901012513576972656C65737320436F6E74726F6C6C6572090102251B536F6E7920436F6D707574657220456E7465727461696E6D656E740902000901000902010901000902020800090203082109020428010902052801090206359A35980822259405010904A101A102850175089501150026FF00810375019513150025013500450105091901291381027501950D0600FF8103150026FF0005010901A10075089504350046FF0009300931093209358102C0050175089527090181027508953009019102750895300901B102C0A1028502750895300901B102C0A10285EE750895300901B102C0A10285EF750895300901B102C0C0090207350835060904090901000902082800090209280109020A280109020B09010009020C093E8009020D280009020E2800
EOF
)"
  [E4:17:D8:C5:67:6D]="$(cat <<"EOF"
[General]
Name=8Bitdo NES30 Pro

[ServiceRecords]
0x00010000=35680900000A000100000900013503191200090004350D350619010009000135031900010900053503191002090006350909656E09006A09010009000935083506191200090100090200092200090201092DC80902020938200902030901000902042801090205090002
0x00020000=3601530900000A000200000900013503191124090004350D350619010009001135031900110900053503191002090006350909656E09006A0901000900093508350619112409010009000D350F350D350619010009001335031900110901002520426C7565746F6F746820576972656C65737320436F6E74726F6C6C657220202009010125084A6F7970616420200901022510737A6D792D706F776572204C74642E200902000901000902010901110902020880090203082109020428010902052801090206355C355A0822255605010905A1018503050115002507463B0195017504651409398142750195048101150026FF0009300931093209359504750881020502150026FF0009C409C595027508810205091901291015002501750195108102C0090207350835060904090901000902082800090209280109020A280109020B09010009020C090C8009020D280009020E2801
EOF
)"
)

# device-tree overlays
DTOVERLAY=(
  [gpio-poweroff]="gpiopin=17,active_low=1"
  [gpio-shutdown]="gpio_pin=18,active_low=0,gpio_pull=1"
)

#===============================================================================
# RetroPie Configuration

# packages to be installed from binary
PACKAGES_BINARY=(
  emulationstation
  runcommand
  splashscreen
)

# packages to be installed from source
PACKAGES_SOURCE=(
  retroarch
  lr-genesis-plus-gx
  lr-mgba
  lr-mupen64plus
  lr-nestopia
  lr-pcsx-rearmed
  lr-snes9x
)

# default emulators for systems
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
VIDEO_MODE=(
  [lr-genesis-plus-gx]=CEA-4
  [lr-mgba]=CEA-4
  [lr-mupen64plus]=CEA-4
  [lr-nestopia]=CEA-4
  [lr-pcsx-rearmed]=CEA-4
  [lr-snes9x]=CEA-4
)

# shader preset types for libretro core names
SHADER_PRESET_TYPE=(
  [mGBA]=LCD
  [Genesis Plus GX]=CRT
  [Nestopia]=CRT
  [Mupen64Plus GLES2]=CRT
  [PCSX-ReARMed]=CRT
  [Snes9x]=CRT
)

# shader presets for shader preset types
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

# autoconfigs for retroarch joypads
JOYPAD_AUTOCONFIG=(
  [Sony PLAYSTATION(R)3 Controller]="$(cat <<"EOF"
input_driver = "udev"
input_device = "Sony PLAYSTATION(R)3 Controller"
input_b_btn = "0"
input_a_btn = "1"
input_x_btn = "2"
input_y_btn = "3"
input_select_btn = "8"
input_start_btn = "9"
input_up_btn = "13"
input_down_btn = "14"
input_left_btn = "15"
input_right_btn = "16"
input_l_btn = "4"
input_r_btn = "5"
input_l2_btn = "6"
input_r2_btn = "7"
input_l3_btn = "11"
input_r3_btn = "12"
input_l_x_plus_axis = "+0"
input_l_x_minus_axis = "-0"
input_l_y_plus_axis = "+1"
input_l_y_minus_axis = "-1"
input_r_x_plus_axis = "+3"
input_r_x_minus_axis = "-3"
input_r_y_plus_axis = "+4"
input_r_y_minus_axis = "-4"
input_reset_btn = "0"
input_menu_toggle_btn = "2"
input_load_state_btn = "4"
input_save_state_btn = "5"
input_exit_emulator_btn = "9"
input_enable_hotkey_btn = "10"
input_state_slot_decrease_btn = "15"
input_state_slot_increase_btn = "16"
input_b_btn_label = "Cross"
input_a_btn_label = "Circle"
input_x_btn_label = "Triangle"
input_y_btn_label = "Square"
input_select_btn_label = "Select"
input_start_btn_label = "Start"
input_up_btn_label = "D-Pad Up"
input_down_btn_label = "D-Pad Down"
input_left_btn_label = "D-Pad Left"
input_right_btn_label = "D-Pad Right"
input_l_btn_label = "L1"
input_r_btn_label = "R1"
input_l2_btn_label = "L2"
input_r2_btn_label = "R2"
input_l3_btn_label = "L3"
input_r3_btn_label = "R3"
input_l_x_plus_axis_label = "Left Analog Right"
input_l_x_minus_axis_label = "Left Analog Left"
input_l_y_plus_axis_label = "Left Analog Down"
input_l_y_minus_axis_label = "Left Analog Up"
input_r_x_plus_axis_label = "Right Analog Right"
input_r_x_minus_axis_label = "Right Analog Left"
input_r_y_plus_axis_label = "Right Analog Down"
input_r_y_minus_axis_label = "Right Analog Up"
input_enable_hotkey_btn_label = "PS"
EOF
)"
  [8Bitdo NES30 Pro]="$(cat <<"EOF"
input_driver = "udev"
input_device = "8Bitdo NES30 Pro"
input_a_btn = "0"
input_b_btn = "1"
input_x_btn = "3"
input_y_btn = "4"
input_select_btn = "10"
input_start_btn = "11"
input_up_btn = "h0up"
input_down_btn = "h0down"
input_left_btn = "h0left"
input_right_btn = "h0right"
input_l_btn = "6"
input_r_btn = "7"
input_l2_btn = "8"
input_r2_btn = "9"
input_l3_btn = "13"
input_r3_btn = "14"
input_l_x_plus_axis = "+0"
input_l_x_minus_axis = "-0"
input_l_y_plus_axis = "+1"
input_l_y_minus_axis = "-1"
input_r_x_plus_axis = "+2"
input_r_x_minus_axis = "-2"
input_r_y_plus_axis = "+3"
input_r_y_minus_axis = "-3"
input_reset_btn = "1"
input_enable_hotkey_btn = "2"
input_menu_toggle_btn = "3"
input_load_state_btn = "6"
input_save_state_btn = "7"
input_exit_emulator_btn = "11"
input_state_slot_decrease_btn = "h0left"
input_state_slot_increase_btn = "h0right"
input_a_btn_label = "A"
input_b_btn_label = "B"
input_x_btn_label = "X"
input_y_btn_label = "Y"
input_select_btn_label = "Select"
input_start_btn_label = "Start"
input_up_btn_label = "D-Pad Up"
input_down_btn_label = "D-Pad Down"
input_left_btn_label = "D-Pad Left"
input_right_btn_label = "D-Pad Right"
input_l_btn_label = "L1"
input_r_btn_label = "R1"
input_l2_btn_label = "L2"
input_r2_btn_label = "R2"
input_l3_btn_label = "L3"
input_r3_btn_label = "R3"
input_l_x_plus_axis_label = "Left Analog Right"
input_l_x_minus_axis_label = "Left Analog Left"
input_l_y_plus_axis_label = "Left Analog Down"
input_l_y_minus_axis_label = "Left Analog Up"
input_r_x_plus_axis_label = "Right Analog Right"
input_r_x_minus_axis_label = "Right Analog Left"
input_r_y_plus_axis_label = "Right Analog Down"
input_r_y_minus_axis_label = "Right Analog Up"
input_enable_hotkey_btn_label = "Power"
EOF
)"
)

# joypad remaps for systems/libretro core names
JOYPAD_REMAP=(
  [mastersystem/Genesis Plus GX]="$(cat <<"EOF"
input_player1_btn_b = "1"
input_player1_btn_y = "0"
input_player2_btn_b = "1"
input_player2_btn_y = "0"
input_player3_btn_b = "1"
input_player3_btn_y = "0"
input_player4_btn_b = "1"
input_player4_btn_y = "0"
input_player5_btn_b = "1"
input_player5_btn_y = "0"
EOF
)"
  [nes/Nestopia]="$(cat <<"EOF"
input_player1_btn_a = "9"
input_player1_btn_b = "8"
input_player1_btn_x = "1"
input_player1_btn_y = "0"
input_player2_btn_a = "9"
input_player2_btn_b = "8"
input_player2_btn_x = "1"
input_player2_btn_y = "0"
input_player3_btn_a = "9"
input_player3_btn_b = "8"
input_player3_btn_x = "1"
input_player3_btn_y = "0"
input_player4_btn_a = "9"
input_player4_btn_b = "8"
input_player4_btn_x = "1"
input_player4_btn_y = "0"
input_player5_btn_a = "9"
input_player5_btn_b = "8"
input_player5_btn_x = "1"
input_player5_btn_y = "0"
EOF
)"
)

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
  <inputConfig type="joystick" deviceName="Sony PLAYSTATION(R)3 Controller" deviceGUID="050000004c0500006802000000800000">
    <input name="pageup" type="button" id="4" value="1"/>
    <input name="start" type="button" id="9" value="1"/>
    <input name="down" type="button" id="14" value="1"/>
    <input name="pagedown" type="button" id="5" value="1"/>
    <input name="right" type="button" id="16" value="1"/>
    <input name="select" type="button" id="8" value="1"/>
    <input name="left" type="button" id="15" value="1"/>
    <input name="up" type="button" id="13" value="1"/>
    <input name="a" type="button" id="1" value="1"/>
    <input name="b" type="button" id="0" value="1"/>
    <input name="x" type="button" id="2" value="1"/>
    <input name="y" type="button" id="3" value="1"/>
  </inputConfig>
  <inputConfig type="joystick" deviceName="8Bitdo NES30 Pro" deviceGUID="05000000c82d00002038000000010000">
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
# Post-setup hook

function my_retropie_setup_hook() {
  # disable video threaded option in retroarch
  show_message "Disabling video threaded option in retroarch ..."
  set_retroarch_option "video_threaded" "false" || return

  # set threaded audio driver in retroarch
  show_message "Setting threaded audio driver in retroarch ..."
  set_retroarch_option "audio_driver" "alsathread" || return

  # disable menu in runcommand
  show_message "Disabling menu in runcommand ..."
  set_runcommand_option "disable_menu" "1" || return

  # configure autostart to stop splashscreen sooner
  show_message "Configuring autostart to stop splashscreen sooner ..."
  if ! grep -q "systemctl stop asplashscreen" "$CONFIGS_BASE_DIR"/all/autostart.sh; then
    sed -e "/^emulationstation /i (sleep 2 \\&\\& systemctl is-active --quiet asplashscreen \\&\\& sudo systemctl stop asplashscreen) \\&" \
      -i "$CONFIGS_BASE_DIR"/all/autostart.sh || return
  fi
}

#===============================================================================
# Run MyRetropie

my_retropie "$@"
