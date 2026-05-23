#!/bin/bash

# Fallout Limine Theme Installer for Arch/CachyOS
# Adapted from CachyOS Limine Theme with Fallout GRUB theme aesthetics
# Optimized for Arch Linux and CachyOS with pacman

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo -e "\e[31mThis script must be run as root.\e[0m"
  echo "Usage: sudo $0"
  exit 1
fi

set -e

# Color definitions
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"
BOLD="\e[1m"

THEME_NAME="fallout"
BACKUP_SUFFIX=".bak-$THEME_NAME"
SPLASH_FILE="splash-limine-fallout.png"

# Check dependencies
check_dependencies() {
  local deps=("b2sum" "sed" "mktemp" "grep" "wget")
  local missing_deps=()

  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      missing_deps+=("$dep")
    fi
  done

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    echo -e "${YELLOW}The following packages are missing:${RESET}"
    printf '  - %s\n' "${missing_deps[@]}"
    echo
    read -rp "$(echo -e \"${YELLOW}Install missing packages with pacman? [y/N]: ${RESET}\")" install_deps
    if [[ "$install_deps" =~ ^[Yy]$ ]]; then
      pacman -Syu --noconfirm "${missing_deps[@]}"
    else
      echo -e "${RED}Cannot proceed without dependencies.${RESET}"
      exit 1
    fi
  fi
}

# Fallout color palette (green terminal text, black background)
# Colors: #67d97a (Fallout green), #000000 (black)
PARAMS=(
  "term_palette: 000000;ff0000;67d97a;ffff00;0000ff;ff00ff;67d97a;ffffff"
  "term_palette_bright: 333333;ff0000;67d97a;ffff00;0000ff;ff00ff;67d97a;ffffff"
  "term_background: ffffffff"
  "term_foreground: 67d97a"
  "term_background_bright: ffffffff"
  "term_foreground_bright: ffffff"
  "interface_branding:"
)

# GitHub raw content URL for the splash image
SPLASH_IMAGE_URL="https://raw.githubusercontent.com/magicdude4eva/fallout-limine-theme/refs/heads/main/splash-limine-fallout.png"

# Search for limine.conf recursively under /boot
find_limine_conf() {
  find /boot -type f -name "limine.conf" 2>/dev/null | head -n 1
}

# Calculate b2sum hash for the wallpaper
calculate_b2sum() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo ""
    return 1
  fi

  b2sum "$file" | awk '{print $1}'
}

# Ask the user if they want to reboot
prompt_reboot() {
  echo
  read -rp "$(echo -e ${YELLOW}Do you want to reboot now to apply the changes? [y/N]: ${RESET})" reboot
  if [[ "$reboot" =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}Rebooting...${RESET}"
    sleep 2
    reboot
  else
    echo -e "${GREEN}Operation completed. Please reboot later to apply the changes.${RESET}"
  fi
}

# Install the theme and modify limine.conf
install_theme() {
  limine_conf=$(find_limine_conf)
  if [[ -z "$limine_conf" ]]; then
    echo -e "${RED}Error:${RESET} limine.conf not found in /boot."
    echo -e "${YELLOW}Make sure Limine bootloader is installed.${RESET}"
    return
  fi

  # Check if limine-update is available
  if ! command -v limine-update &> /dev/null; then
    echo -e "${YELLOW}Warning: limine-update not found in PATH.${RESET}"
    echo -e "${YELLOW}Please ensure limine is installed and limine-update is available.${RESET}"
    read -rp "$(echo -e \"${YELLOW}Continue without updating bootloader? [y/N]: ${RESET}\")" continue_without_update
    if [[ ! "$continue_without_update" =~ ^[Yy]$ ]]; then
      return 1
    fi
  fi

  echo -e "${GREEN}Found:${RESET} $limine_conf"
  backup_file="${limine_conf}${BACKUP_SUFFIX}"

  if [[ -f "$backup_file" ]]; then
    read -rp "$(echo -e ${YELLOW}A backup already exists. Overwrite it? [y/N]: ${RESET})" confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      cp "$limine_conf" "$backup_file"
      echo -e "${GREEN}Backup overwritten:${RESET} $backup_file"
    else
      echo -e "${YELLOW}Continuing without modifying the existing backup.${RESET}"
    fi
  else
    cp "$limine_conf" "$backup_file"
    echo -e "${GREEN}Backup created:${RESET} $backup_file"
  fi

  echo -e "${CYAN}Removing old Fallout theme parameters...${RESET}"
  for param in "${PARAMS[@]}"; do
    key="${param%%:*}"
    sed -i "/^$key:/d" "$limine_conf"
  done

  # Remove any existing wallpaper entry (both old and new format)
  sed -i "/^wallpaper:/d" "$limine_conf"

  echo -e "${CYAN}Adding Fallout theme block...${RESET}"

  # Create a temporary file with the theme block at the top
  temp_file=$(mktemp)

  # Write the theme block header
  cat << 'EOF' > "$temp_file"
# Fallout Limine Theme
# Author: magicdude4eva (https://github.com/magicdude4eva/fallout-limine-theme)
EOF

  # Write all theme parameters except wallpaper
  for param in "${PARAMS[@]}"; do
    if [[ "$param" != wallpaper* ]]; then
      echo "$param" >> "$temp_file"
    fi
  done

  # Add empty line and wallpaper entry
  echo "" >> "$temp_file"
  echo "$wallpaper_entry" >> "$temp_file"

  # Add empty line and the rest of the original config (without any existing theme params)
  echo "" >> "$temp_file"

  # Only keep lines that don't match our theme parameters
  grep -vE "^(term_palette|term_palette_bright|term_background|term_foreground|term_background_bright|term_foreground_bright|interface_branding|wallpaper):" "$limine_conf" >> "$temp_file"

  # Replace original file
  mv "$temp_file" "$limine_conf"

  theme_dir=$(dirname "$limine_conf")

  # Verify theme directory is writable
  if [[ ! -w "$theme_dir" ]]; then
    echo -e "${RED}Error: Cannot write to $theme_dir.${RESET}"
    echo -e "${YELLOW}Check permissions and try again.${RESET}"
    return 1
  fi

  # Download splash image directly from GitHub
  echo -e "${CYAN}Downloading Fallout splash image from GitHub...${RESET}"
  echo -e "${YELLOW}URL: $SPLASH_IMAGE_URL${RESET}"

  # Check if wget is available
  if ! command -v wget &> /dev/null; then
    echo -e "${RED}Error: wget is not installed.${RESET}"
    echo -e "${YELLOW}Please install wget and try again.${RESET}"
    echo -e "${YELLOW}Command: pacman -S wget${RESET}"
    return 1
  fi

  # Download the splash image
  if ! wget -q "$SPLASH_IMAGE_URL" -O "$theme_dir/$SPLASH_FILE"; then
    echo -e "${RED}Error: Failed to download splash image.${RESET}"
    echo -e "${YELLOW}Check your internet connection and try again.${RESET}"
    echo -e "${YELLOW}Check write permissions in $theme_dir.${RESET}"
    return 1
  fi

  wallpaper_path="$theme_dir/$SPLASH_FILE"
  echo -e "${CYAN}Calculating b2sum hash for splash image...${RESET}"
  wallpaper_hash=$(calculate_b2sum "$wallpaper_path")

  if [[ -z "$wallpaper_hash" ]]; then
    echo -e "${RED}Error: Could not calculate b2sum hash.${RESET}"
    echo -e "${YELLOW}The downloaded image may be corrupted.${RESET}"
    return 1
  else
    echo -e "${GREEN}Splash image hash:${RESET} $wallpaper_hash"
    wallpaper_entry="wallpaper: boot():/$SPLASH_FILE#$wallpaper_hash"
  fi

  # Add wallpaper entry to limine.conf
  echo "$wallpaper_entry" >> "$limine_conf"

  echo
  echo -e "${GREEN}${BOLD}Theme installed successfully!${RESET}"
  echo -e "${CYAN}Configuration file:${RESET} $limine_conf"

  echo -e "${CYAN}Recreating bootloader via limine-update...${RESET}"
  if ! limine-update; then
    echo -e "${RED}Error: limine-update failed!${RESET}"
    echo -e "${YELLOW}Your bootloader may not be updated.${RESET}"
    echo -e "${YELLOW}Please run 'limine-update' manually after fixing any issues.${RESET}"
  else
    echo -e "${GREEN}Bootloader updated successfully!${RESET}"
  fi

  prompt_reboot
}

# Restore the backup and remove the theme
remove_theme() {
  limine_conf=$(find_limine_conf)
  if [[ -z "$limine_conf" ]]; then
    echo -e "${RED}Error:${RESET} limine.conf not found in /boot."
    return
  fi

  echo -e "${GREEN}Found:${RESET} $limine_conf"
  backup_file="${limine_conf}${BACKUP_SUFFIX}"

  if [[ ! -f "$backup_file" ]]; then
    echo -e "${RED}No backup found to restore.${RESET}"
    return
  fi

  echo -e "${CYAN}Restoring backup...${RESET}"
  cp "$backup_file" "$limine_conf"
  rm -f "$backup_file"

  theme_dir=$(dirname "$limine_conf")
  echo -e "${CYAN}Removing Fallout splash image...${RESET}"
  rm -f "$theme_dir/$SPLASH_FILE"

  echo
  echo -e "${GREEN}${BOLD}Theme removed and backup restored!${RESET}"

  prompt_reboot
}

# Manually edit limine.conf using micro
edit_limine_conf() {
    limine_conf=$(find_limine_conf)
    if [[ -z "$limine_conf" ]]; then
        echo -e "${RED}Error:${RESET} limine.conf not found in /boot."
        pause
        return
    fi

    if ! command -v micro >/dev/null 2>&1; then
        echo -e "${RED}[ERROR]${RESET} micro editor is not installed."
        echo "Install it with: pacman -S micro"
        pause
        return
    fi

    echo -e "${GREEN}Opening:${RESET} $limine_conf"
    echo -e "${YELLOW}with:${RESET} ${BOLD}micro${RESET}"
    sleep 1
    micro "$limine_conf"
    echo -e "${GREEN}Editing completed.${RESET}"
    pause
}

# Function to pause (for consistent user interaction)
pause() {
    echo
    read -r -p "Press Enter to return to the main menu..." < /dev/tty
    clear
}

# Display current theme info
show_theme_info() {
    limine_conf=$(find_limine_conf)
    if [[ -z "$limine_conf" ]]; then
        echo -e "${RED}limine.conf not found.${RESET}"
        pause
        return
    fi

    clear
    echo -e "${BOLD}Fallout Limine Theme - Current Configuration${RESET}"
    echo -e "${CYAN}============================================${RESET}"
    echo
    echo -e "${CYAN}Configuration file:${RESET} $limine_conf"
    echo
    echo -e "${CYAN}Current settings:${RESET}"
    grep -E "^(term_palette|term_foreground|term_background|wallpaper|timeout|interface_branding)" "$limine_conf" || echo "No Fallout theme settings found"
    echo
    pause
}

# Main menu loop
while true; do
  clear
  echo
  echo -e "${BOLD}Fallout Limine Theme Installer for Arch Linux / CachyOS${RESET}"
  echo -e "${CYAN}=======================================================${RESET}"
  echo
  echo -e "${BOLD}Choose an option:${RESET}"
  echo -e "${CYAN}1)${RESET} Install theme"
  echo -e "${CYAN}2)${RESET} Remove theme and restore backup"
  echo -e "${CYAN}3)${RESET} Edit limine.conf manually"
  echo -e "${CYAN}4)${RESET} Show current theme configuration"
  echo -e "${RED}5)${RESET} Exit"
  read -rp "$(echo -e ${YELLOW}Option [1-5]: ${RESET})" option

  case "$option" in
    1) clear; check_dependencies; install_theme ;;
    2) clear; remove_theme ;;
    3) clear; edit_limine_conf ;;
    4) show_theme_info ;;
    5) echo -e "${YELLOW}Exiting.${RESET}"; exit 0 ;;
    *) echo -e "${RED}Invalid option.${RESET}"; sleep 1 ;;
  esac
done
