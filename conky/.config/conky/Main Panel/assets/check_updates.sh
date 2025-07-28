#!/bin/bash
export PATH=/usr/bin:/bin:/usr/local/bin

CHECKUPDATES="/usr/bin/checkupdates"
YAY="/usr/bin/yay"
PARU="/usr/bin/paru"

sys_updates=$($CHECKUPDATES 2>/dev/null | wc -l)

aur_updates=0
if [ -x "$YAY" ]; then
    aur_updates=$($YAY -Qua 2>/dev/null | wc -l)
elif [ -x "$PARU" ]; then
    aur_updates=$($PARU -Qua 2>/dev/null | wc -l)
fi

total_updates=$((sys_updates + aur_updates))

if [ "$total_updates" -eq 0 ]; then
    echo "System is up-to-date"
else
    echo "$total_updates updates available"
fi
