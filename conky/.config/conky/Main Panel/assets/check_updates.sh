#!/bin/bash

# Parse via Conky: ${execi 1000 assets/check_updates.sh}

# Configuration
CACHE_DIR="/tmp"
CACHE_DURATION=3600 # 1 hour in seconds

# Cache files are dynamically determined based on OS
CACHE_FILE_APT="$CACHE_DIR/package_updates_apt.txt"
CACHE_FILE_PACMAN="$CACHE_DIR/package_updates_pacman.txt"
CACHE_FILE_AUR="$CACHE_DIR/package_updates_aur.txt"
CACHE_FILE_DNF="$CACHE_DIR/package_updates_dnf.txt"

# Function to get the last modification time of a file
last_update() {
    local file="$1"
    if [[ -f "$file" ]]; then
        stat -c %Y "$file" 2>/dev/null || echo 0
    else
        echo 0
    fi
}

# Function to detect the operating system
detect_os() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        case "$ID" in
            "debian"|"ubuntu")
                echo "debian"
                ;;
            "arch"|"manjaro"|"endeavouros"|"garuda"|"arcolinux"|"rebornos"|"archlabs"|"chakra"|"anarchy"|"cachyos"|"blendos")
                echo "arch"
                ;;
            "fedora")
                echo "fedora"
                ;;
            *)
                echo "unsupported"
                ;;
        esac
    else
        echo "unsupported"
    fi
}

# Function to update cache based on OS
update_cache() {
    local os="$1"
    local current_time
    current_time=$(date +%s)

    case "$os" in
        "debian")
            if [[ $((current_time - $(last_update "$CACHE_FILE_APT"))) -gt $CACHE_DURATION ]]; then
                apt list --upgradable > "$CACHE_FILE_APT" 2>/dev/null
            fi
            ;;
        "arch")
            if [[ $((current_time - $(last_update "$CACHE_FILE_PACMAN"))) -gt $CACHE_DURATION ]]; then
                checkupdates > "$CACHE_FILE_PACMAN" 2>/dev/null
            fi
            if [[ $((current_time - $(last_update "$CACHE_FILE_AUR"))) -gt $CACHE_DURATION ]]; then
                if command -v yay >/dev/null 2>&1; then
                    yay -Qua > "$CACHE_FILE_AUR" 2>/dev/null
                elif command -v paru >/dev/null 2>&1; then
                    paru -Qua > "$CACHE_FILE_AUR" 2>/dev/null
                fi
            fi
            ;;
        "fedora")
            if [[ $((current_time - $(last_update "$CACHE_FILE_DNF"))) -gt $CACHE_DURATION ]]; then
                dnf check-update --refresh > "$CACHE_FILE_DNF" 2>/dev/null
            fi
            ;;
        *)
            echo "No supported package manager found"
            exit 1
            ;;
    esac
}

# Function to load and count package updates
load_package_lines() {
    local os
    os=$(detect_os)
    local original_lines=()
    local update_count

    # Update cache for the detected OS
    update_cache "$os"

    # Process updates based on OS
    case "$os" in
        "debian")
            if [[ -f "$CACHE_FILE_APT" ]]; then
                while IFS= read -r line; do
                    # Skip the first line ("Listing...")
                    if [[ ! "$line" =~ ^Listing... ]]; then
                        # Extract package name before the first slash
                        package_name=$(echo "$line" | grep -oP '^[^/]+' | sed 's|/.*||')
                        if [[ -n "$package_name" ]]; then
                            # Limit length to 20 characters
                            if [[ ${#package_name} -gt 20 ]]; then
                                package_name="${package_name:0:17}..."
                            fi
                            original_lines+=("$package_name")
                        fi
                    fi
                done < "$CACHE_FILE_APT"
            fi
            ;;
        "arch")
            if [[ -f "$CACHE_FILE_PACMAN" ]]; then
                while IFS= read -r line; do
                    package_name=$(echo "$line" | awk '{print $1}')
                    if [[ -n "$package_name" ]]; then
                        original_lines+=("$package_name")
                    fi
                done < "$CACHE_FILE_PACMAN"
            fi
            if [[ -f "$CACHE_FILE_AUR" ]]; then
                if command -v yay >/dev/null 2>&1 || command -v paru >/dev/null 2>&1; then
                    while IFS= read -r line; do
                        package_name=$(echo "$line" | awk '{print $1}')
                        if [[ -n "$package_name" ]]; then
                            original_lines+=("$package_name")
                        fi
                    done < "$CACHE_FILE_AUR"
                fi
            fi
            ;;
        "fedora")
            if [[ -f "$CACHE_FILE_DNF" ]]; then
                # Skip lines that don't contain package names (e.g., empty lines, headers)
                while IFS= read -r line; do
                    # Check if the line contains a package name (starts with a word, followed by a version)
                    if [[ "$line" =~ ^[a-zA-Z0-9._-]+[[:space:]]+[0-9] ]]; then
                        package_name=$(echo "$line" | awk '{print $1}')
                        if [[ -n "$package_name" ]]; then
                            # Limit length to 20 characters
                            if [[ ${#package_name} -gt 20 ]]; then
                                package_name="${package_name:0:17}..."
                            fi
                            original_lines+=("$package_name")
                        fi
                    fi
                done < "$CACHE_FILE_DNF"
            fi
            ;;
        *)
            echo "No supported package manager found"
            exit 1
            ;;
    esac

    # Count the number of updates
    update_count=${#original_lines[@]}

    # Output result
    if [[ $update_count -eq 0 ]]; then
        echo "System is up-to-date"
    else
        echo "$update_count updates available"
    fi
}

# Main function to display updates
updates_block() {
    load_package_lines
}

# Call the function
updates_block