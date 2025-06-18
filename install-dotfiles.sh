#!/bin/bash

# Dotfiles Installation Script
# This script installs dotfiles from the current directory using GNU Stow

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Welcome message
echo -e "${BLUE}=== Dotfiles Installation Script ===${NC}"
echo ""
echo "This script will install your dotfiles using GNU Stow."
echo "It will create symbolic links from your dotfiles to their appropriate locations in your home directory."
echo ""
echo -e "${YELLOW}Prerequisites:${NC}"
echo "- GNU Stow must be installed"
echo ""

# Ask for confirmation
read -p "Do you want to continue? [Y/n]: " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    echo -e "${RED}Error: GNU Stow is not installed!${NC}"
    echo "Please install stow first:"
    echo "  Ubuntu/Debian: sudo apt install stow"
    echo "  macOS: brew install stow"
    echo "  Arch Linux: sudo pacman -S stow"
    exit 1
fi

echo -e "${GREEN}✓ GNU Stow found${NC}"
echo ""

# Get current directory (should be ~/dotfiles)
DOTFILES_DIR="$(pwd)"

echo -e "${BLUE}Installing dotfiles from: $DOTFILES_DIR${NC}"
echo ""

# Arrays to track failed packages and their errors
failed_packages=()
conflict_packages=()

# Get all directories (potential stow packages), excluding hidden dirs and common non-package dirs
for package in */; do
    # Remove trailing slash
    package=${package%/}
    
    # Skip if not a directory, if it's hidden, or common non-package directories
    if [ ! -d "$package" ] || [[ "$package" == .* ]] || [[ "$package" == "scripts" ]] || [[ "$package" == "docs" ]] || [[ "$package" == "README"* ]]; then
        continue
    fi
    
    echo -n "Installing $package... "
    
    # Create target directories if they don't exist
    if [ -d "$package" ]; then
        find "$package" -type d | while read -r dir; do
            target_dir="$HOME/${dir#$package/}"
            if [ "$target_dir" != "$HOME/" ] && [ ! -d "$target_dir" ]; then
                mkdir -p "$target_dir" 2>/dev/null || true
            fi
        done
    fi
    
    # Try to stow the package
    stow_output=$(stow -t "$HOME" "$package" 2>&1) || stow_result=$?
    
    if [ ${stow_result:-0} -eq 0 ]; then
        echo -e "${GREEN}✓ Success${NC}"
    else
        echo -e "${RED}✗ Failed${NC}"
        if [[ $stow_output == *"existing target is"* ]] || [[ $stow_output == *"conflict"* ]]; then
            conflict_packages+=("$package")
        else
            failed_packages+=("$package")
            echo -e "${RED}    Error: $stow_output${NC}"
        fi
    fi
    
    # Reset stow_result for next iteration
    unset stow_result
done

echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""

# Handle conflicts if any
if [ ${#conflict_packages[@]} -gt 0 ]; then
    echo -e "${YELLOW}The following packages have conflicts with existing files:${NC}"
    for pkg in "${conflict_packages[@]}"; do
        echo "  - $pkg"
    done
    echo ""
    
    read -p "Do you want to overwrite existing files and force install these packages? [y/N]: " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${BLUE}Force installing conflicted packages...${NC}"
        echo ""
        
        for package in "${conflict_packages[@]}"; do
            echo -n "Force installing $package... "
            
            # First try to unstow any conflicting packages that might have already installed the same files
            # This handles cases where multiple packages contain the same config files
            for other_package in */; do
                other_package=${other_package%/}
                if [ "$other_package" != "$package" ] && [ -d "$other_package" ]; then
                    # Silently try to unstow, ignore errors
                    stow -D -t "$HOME" "$other_package" 2>/dev/null || true
                fi
            done
            
            # Now try to stow our package
            force_output=$(stow -t "$HOME" "$package" 2>&1) || force_result=$?
            
            if [ ${force_result:-0} -eq 0 ]; then
                echo -e "${GREEN}✓ Success${NC}"
                # Restow other packages that were unstowed
                for other_package in */; do
                    other_package=${other_package%/}
                    if [ "$other_package" != "$package" ] && [ -d "$other_package" ] && [[ ! "$other_package" == .* ]] && [[ ! "$other_package" == "scripts" ]] && [[ ! "$other_package" == "docs" ]] && [[ ! "$other_package" == README* ]]; then
                        stow -t "$HOME" "$other_package" 2>/dev/null || true
                    fi
                done
            else
                echo -e "${RED}✗ Failed${NC}"
                echo -e "${RED}    Error: $force_output${NC}"
                failed_packages+=("$package")
                
                # Restow other packages since we failed
                for other_package in */; do
                    other_package=${other_package%/}
                    if [ "$other_package" != "$package" ] && [ -d "$other_package" ] && [[ ! "$other_package" == .* ]] && [[ ! "$other_package" == "scripts" ]] && [[ ! "$other_package" == "docs" ]] && [[ ! "$other_package" == README* ]]; then
                        stow -t "$HOME" "$other_package" 2>/dev/null || true
                    fi
                done
            fi
            
            # Reset variables for next iteration
            unset force_result
        done
        echo ""
    fi
fi

# Report final status
if [ ${#failed_packages[@]} -eq 0 ]; then
    echo -e "${GREEN}All dotfiles have been successfully installed!${NC}"
else
    echo -e "${YELLOW}Some packages failed to install:${NC}"
    for pkg in "${failed_packages[@]}"; do
        echo "  - $pkg"
    done
    echo ""
    echo "You can manually resolve issues and re-run individual packages with:"
    echo "  stow <package-name>"
fi

echo ""
echo "Your dotfiles have been installed using GNU Stow."
echo "Symbolic links have been created in your home directory."
