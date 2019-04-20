#!/bin/bash

# Script to set a custom background or slideshow for Cinnamon's default lockscreen & screensaver
# Built and tested with Cinnamon 4.0.9 on Mint 19.1, but will probably work with older versions of Cinnamon
# Save the script as ~/bin/lock_screen_slideshow.sh or ~/.local/bin/lock_screen_slideshow.sh and make executable
# Add a entry to Startup Applications to launch the script after user login with a delay of 30 seconds

# These variables are intended to be set by the end user.

# Set SLIDESHOW to true if you want a lock-screen / screensaver slideshow, false if you want a static image
SLIDESHOW=true

# Set STATIC_BACKGROUND to the path to your image of choice for static image mode
STATIC_BACKGROUND="/usr/share/backgrounds/linuxmint/default_background.jpg"

# Set SLIDESHOW_DIR to a directory of your choice
# This directory and it's sub-directorys will be searched for images
# for display in a random order in slideshow mode
SLIDESHOW_DIR="/usr/share/backgrounds"

# INTERVAL is the time time in seconds between background transitions in slideshow mode
INTERVAL=10

# Main script starts here
# Check for existing instance and exit if already running
if pidof -o %PPID -x "${0##*/}"; then
  exit 1
fi
# set initial status
ACTIVE=false
# Start the main loop to monitor screensaver status changes
dbus-monitor --profile "interface='org.cinnamon.ScreenSaver', member='ActiveChanged'" | while read -r
do
  # Screensaver active loop.
  while $(qdbus org.cinnamon.ScreenSaver /org/cinnamon/ScreenSaver org.cinnamon.ScreenSaver.GetActive) == true
  do
    # If screensaver just activated check status of native background slide-show, get user background and either set static
    # lock screen background or start slideshow
    if ( ! $ACTIVE ) ; then
      NATIVE_SLIDESHOW_STATE=$(gsettings get org.cinnamon.desktop.background.slideshow slideshow-enabled)
      DESK_BACKGROUND=$(gsettings get org.cinnamon.desktop.background picture-uri)
      ACTIVE=true
      if ( ! $SLIDESHOW ) ; then
        gsettings set org.cinnamon.desktop.background picture-uri "file://$STATIC_BACKGROUND"
      fi
      TIMER="$INTERVAL"
    fi
    # Update background if in slideshow mode
    if ( $SLIDESHOW ); then
      if [ $TIMER == $INTERVAL ] ; then
        LOCK_BACKGROUND=$(find "$SLIDESHOW_DIR" -iname '*.jp*g' -o -iname '*.png' | shuf -n1)
        gsettings set org.cinnamon.desktop.background picture-uri "file://$LOCK_BACKGROUND"
        TIMER=0
      fi
      ((TIMER++))
    fi
    sleep 1
  done 
  # Set background back to the user background and unpause native slideshow on screensaver de-activation
  if ( $ACTIVE ) ; then
    if ( $NATIVE_SLIDESHOW_STATE ) ; then
      gsettings set org.cinnamon.desktop.background.slideshow slideshow-enabled "$NATIVE_SLIDESHOW_STATE"
    else
      gsettings set org.cinnamon.desktop.background picture-uri "$DESK_BACKGROUND"
    fi
    ACTIVE=false
  fi
done
