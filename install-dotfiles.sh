#!/bin/bash

# Fast Dotfiles Installation Script using GNU Stow

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Dotfiles Installation Script ===${NC}\n"
echo "(optimized by Poprex)"
echo "This script installs your dotfiles using GNU Stow."
echo -e "${YELLOW}Make sure GNU Stow is installed.${NC}\n"

read -p "Do you want to continue? [Y/n]: " -n 1 -r
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Check for stow
if ! command -v stow &>/dev/null; then
    echo -e "${RED}Error: GNU Stow is not installed!${NC}"
    echo "Install it using your package manager."
    exit 1
fi
echo -e "${GREEN}✓ GNU Stow found${NC}\n"

DOTFILES_DIR="$(pwd)"
echo -e "${BLUE}Installing from: $DOTFILES_DIR${NC}\n"

# Initialize status arrays
failed_packages=()
conflict_packages=()

# Filter valid stow packages
packages=()
for dir in */; do
    dir=${dir%/}
    [[ "$dir" =~ ^(\.|scripts|docs|README) ]] && continue
    [[ -d "$dir" ]] && packages+=("$dir")
done

# Stow each package
for pkg in "${packages[@]}"; do
    echo -n "Installing $pkg... "
    if output=$(stow -t "$HOME" "$pkg" 2>&1); then
        echo -e "${GREEN}✓ Success${NC}"
    else
        echo -e "${RED}✗ Failed${NC}"
        if [[ $output == *"existing target is"* || $output == *"conflict"* ]]; then
            conflict_packages+=("$pkg")
        else
            failed_packages+=("$pkg")
            echo -e "${RED}    Error: $output${NC}"
        fi
    fi
done

echo -e "\n${GREEN}=== Initial Installation Complete ===${NC}\n"

# Handle conflicts
if [ ${#conflict_packages[@]} -gt 0 ]; then
    echo -e "${YELLOW}Conflicts detected in:${NC}"
    for pkg in "${conflict_packages[@]}"; do echo "  - $pkg"; done
    echo ""
    read -p "Force overwrite and install these packages? [y/N]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "\n${BLUE}Force installing conflicted packages...${NC}\n"
        for pkg in "${conflict_packages[@]}"; do
            echo -n "Force installing $pkg... "
            # Remove conflicting files manually
            unstow_output=$(stow -D -t "$HOME" "$pkg" 2>/dev/null || true)
            if output=$(stow -t "$HOME" "$pkg" 2>&1); then
                echo -e "${GREEN}✓ Success${NC}"
            else
                echo -e "${RED}✗ Failed${NC}"
                echo -e "${RED}    Error: $output${NC}"
                failed_packages+=("$pkg")
            fi
        done
    fi
fi

# Final status
if [ ${#failed_packages[@]} -eq 0 ]; then
    echo -e "${GREEN}All dotfiles successfully installed!${NC}"
else
    echo -e "${YELLOW}Some packages failed:${NC}"
    for pkg in "${failed_packages[@]}"; do echo "  - $pkg"; done
    echo -e "\nTry resolving manually and run:\n  stow <package-name>"
fi

echo -e "\n${BLUE}Dotfiles installation complete.${NC}"
