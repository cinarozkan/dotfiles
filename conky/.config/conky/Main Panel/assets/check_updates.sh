#!/bin/bash

# Get the update count with yay (all the repos and aur)
updates=$(yay -Sy --noconfirm > /dev/null 2>&1; yay -Qu | wc -l)

# Return string
if [ "$updates" -eq 0 ]; then
  echo "System is up to date"
else
  echo "$updates updates available"
fi
