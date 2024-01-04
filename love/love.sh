#!/bin/bash

# For Andrea, I love you, Babe!
# (c) 2023 // Sam Dennon

# Set the directory containing the images
image_directory="./images/"

# Set the screen session name
screen_session="love"

# Set the path to led-image-viewer
led_image_viewer="/usr/bin/led-image-viewer"

# Set LED display parameters
led_gpio_mapping="adafruit-hat-pwm"
led_cols=64 # int is number of pixels vertically
led_rows=64 # int is number of pixels horizontally
led_slowdown_gpio=4 # int 1-4 (Higher number RPIs needing higher number 
led_brightness=40 # int is a percentage of 100%
image_display_duration=60 # int in seconds
is_random=true # display images in random order true|false

check_random(){
   if [ "$is_random" = true ]; then
      echo "-s"
   else
      echo ""
   fi
}

# Additional flags for led-image-viewer
viewer_flags="-f -w${image_display_duration} $(check_random)"

# Create a space-separated list of image files
image_list=$(find images -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) 2>/dev/null | tr '\n' ' ')

# Check if the list is not empty
if [ -n "$image_list" ]; then
    # Check if the screen session already exists
    if screen -list | grep -q "$screen_session"; then
        # a screen session exists, let us kill now to avoid conflicts
        /usr/bin/screen -S "$screen_session" -X quit
    fi
    # create a new screen session that we can stuff into
    /usr/bin/screen  -S "$screen_session" -dm
    # Execute led-image-viewer with the list of image files
    /usr/bin/screen -S "$screen_session" -X stuff "$led_image_viewer --led-gpio-mapping=$led_gpio_mapping --led-cols=$led_cols --led-rows=$led_rows --led-slowdown-gpio=$led_slowdown_gpio --led-brightness=$led_brightness $viewer_flags $image_list$(printf '\r')"
else
    echo "No image files found in $image_directory"
fi