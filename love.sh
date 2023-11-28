#!/bin/bash

# For Andrea on our 3rd Anniversary! I love you, Babe!
# 2023 (c) Sam Dennon

# Set the directory containing the images
image_directory="."

# Set the screen session name
screen_session="love"

# Set the path to led-image-viewer
led_image_viewer="/usr/bin/led-image-viewer"

# Set LED display parameters
led_cols=64 # int is number of pixels vertically
led_rows=64 # int is number of pixels horizontally
led_slowdown_gpio=4 # int 1-4 (Higher number RPIs needing higher number 
led_brightness=40 # int is a percentage of 100%
image_display_duration=30 # int in seconds
is_random=false # display images in random order true|false

check_random(){
   if [ "$is_random" = true ]; then
      echo "-s"
   else
      echo ""
   fi
}

# Additional flags for led-image-viewer
viewer_flags="-f -w${image_display_duration}"

# Create a space-separated list of image files
image_list=$(find . -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) | tr '\n' ' ')

# Check if the list is not empty
if [ -n "$image_list" ]; then
    # Check if the screen session already exists
    if ! screen -list | grep -q "$screen_session"; then
        # Create a new screen session
        sudo /usr/bin/screen -S "$screen_session" -dm
    fi

    # Execute led-image-viewer with the list of image files
    sudo /usr/bin/screen -S "$screen_session" -X stuff "$led_image_viewer --led-cols=$led_cols --led-rows=$led_rows --led-slowdown-gpio=$led_slowdown_gpio --led-brightness=$led_brightness $(check_random) $viewer_flags $image_list$(printf '\r')"
else
    echo "No image files found in $image_directory"
fi
