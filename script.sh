#!/bin/bash

# Define location and name of mounted usb
folder="/media/PLAYOUT"
default_bg="/home/sysadmin/background.png"
log_file="/home/sysadmin/script.log"

# Define the number of connected screens
n_screens=2


# ------------------------------------------------
# Archive old logfile and creating new one
# ------------------------------------------------

if [ -f $log_file ]; then
  mv -f $log_file $log_file.archive
fi
echo "[INFO] - Starting script and logging" > $log_file
echo "[INFO] - Starting script and logging" 


# ------------------------------------------------
# Start X Server and configuring the monitors
# ------------------------------------------------
startx -- -nocursor &> startx.log &
echo "[INFO] - X Server started" | tee -a $log_file
sleep 10
export DISPLAY=:0.0
  # Extract connected displays
connected_displays=$(xrandr | grep " connected" | awk '{print $1}')
  # Set initial command string
xrandr_cmd="xrandr"
  # Add commands for each display
for display in $connected_displays; do
  xrandr_cmd+=" --output $display --auto"
  if [ "$prev_display" ]; then
    xrandr_cmd+=" --right-of ${prev_display}"
  fi
  prev_display=$display
done
  # Run the command
$xrandr_cmd


# ------------------------------------------------
# Set Wallpaper
# ------------------------------------------------
background_cmd="feh --bg-fill "
  # Add commands for each display
for display in $connected_displays; do
  background_cmd+=" $default_bg"
done
  # Run the command
$background_cmd
echo "[INFO] - Wallpaper set" | tee -a $log_file


# ------------------------------------------------
# Main Loop
# ------------------------------------------------
while true; do

  # Wait till usb is mounted
  while [ ! -d "$folder" ]; do
    echo "[INFO] - USB not mounted" | tee -a $log_file
    sleep 5  # wait for 5 seconds
  done

  # Check if subfolders exist. If not -> create them
  for ((i=1; i<=$n_screens; i++))
  do
    if [ -d "$folder/SCREEN$i/.playlist.m3u" ]; then
      echo "[INFO] - Playlist exist already. Deleting Playlist" | tee -a $log_file
      rm "$folder/SCREEN$i/.playlist.m3u"
    fi
    echo "[INFO] - Creating Playlist .playlist.m3u" | tee -a $log_file
    touch "$folder/SCREEN$i/.playlist.m3u"
    echo "#EXTM3U" > "$folder/SCREEN$i/.playlist.m3u"
    # Loop over all mp4, mkv, and mov files in the directory to create the playlist
    for video_file in "$folder/SCREEN$i"/*.mp4 "$folder/SCREEN$i"/*.mkv; do
      # Check if the file exists and is a regular file
      if [ -f "$video_file" ]; then
        echo "#EXTINF:-1,$(basename "$folder/SCREEN$i/$video_file")" >> "$folder/SCREEN$i/.playlist.m3u"
        echo "$video_file" >> "$folder/SCREEN$i/.playlist.m3u"
      fi
    done
  done

  # Display custom background if available
  if [ -f "$folder/background.png" ]; then
    background_cmd="feh --bg-fill "
      # Add commands for each display
    for display in $connected_displays; do
      background_cmd+=" $folder/background.png"
    done
      # Run the command
    $background_cmd
    echo "[INFO] - Custom Wallpaper set" | tee -a $log_file
  fi

  # Playing videos
  for ((i=1; i<=$n_screens; i++))
  do
    screen_no=$((i-1))
    echo "[INFO] - Playing SCREEN$i" | tee -a $log_file
    mpv --ao=null --vo=gpu --fs --screen=$screen_no --no-osc --hwdec-codecs=all --loop-playlist "$folder/SCREEN$i/.playlist.m3u" &> mpv_screen$i.log &
  done

  while [ -d "$folder" ]; do
    sleep 10
  done

done
