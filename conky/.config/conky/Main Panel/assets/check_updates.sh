#!/bin/bash

if pgrep -x pacman >/dev/null; then
    echo "pacman busy"
    exit 0
fi

updates=$(checkupdates 2>/dev/null | wc -l)
aur=$(yay -Qua 2>/dev/null | wc -l)

total=$((updates + aur))

if [ "$total" -eq 0 ]; then
    echo "System is up to date"
else
    echo "$total updates available"
fi
