#!/bin/bash

# Get the update count (all the repos and aur)
updates=$(yay -Qu | wc -l)

# Return string
if [ "$updates" -eq 0 ]; then
  echo "System is up to date"
else
  echo "$updates updates available"
fi
