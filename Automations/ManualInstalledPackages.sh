#!/bin/bash

OUT="$HOME/manual-packages-by-repo.txt"

RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
GRAY="\e[90m"
RESET="\e[0m"

echo -e "${BLUE}Arch Linux – Manually Installed Packages Per Repo${RESET}"
echo -e "${GRAY}Extracting...${RESET}\n"

declare -A REPOS

while read -r pkg; do
    repo=$(pacman -Qi "$pkg" 2>/dev/null | awk -F': ' '/^Repository/ {print $2}')
    repo=${repo:-AUR}
    REPOS["$repo"]+="$pkg"$'\n'
done < <(pacman -Qe | awk '{print $1}')

{
    for repo in $(printf "%s\n" "${!REPOS[@]}" | sort); do
        [[ -z ${REPOS[$repo]} ]] && continue
        echo "[$repo]"
        echo "${REPOS[$repo]}"
    done
} | sed '/^$/d' > "$OUT"

echo -e "${GREEN}✔ Done${RESET}"
echo -e "${BLUE}📄 File:${RESET} $OUT"
