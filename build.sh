#!/bin/bash

# --- 1. Pre-Flight Checks ---
if [[ $EUID -ne 0 ]]; then
   echo -e "\e[31mERROR: This script must be run as root (use sudo).\e[0m"
   exit 1
fi

if ! command -v mkarchiso &> /dev/null; then
    echo -e "\e[31mERROR: 'mkarchiso' is not installed. Run: sudo pacman -S archiso\e[0m"
    exit 1
fi

PROFILE_DIR=$(pwd)
INSTALLER_DIR="$PROFILE_DIR/airootfs/root/ml4w-installer"

echo -e "\e[34m==> Starting ML4W ISO Build Process\e[0m"
echo "Profile Directory: $PROFILE_DIR"

# --- 2. Fix Permissions ---
echo -e "\e[33m==> Fixing executable permissions...\e[0m"
if [ -d "$INSTALLER_DIR" ]; then
    chmod +x "$INSTALLER_DIR"/*.sh
    chmod +x "$INSTALLER_DIR/modules"/*.sh
    echo "Permissions set for installer scripts."
else
    echo -e "\e[31mWARNING: Installer directory not found at $INSTALLER_DIR\e[0m"
fi

# Make sure Matugen and Oh-My-Posh are executable on the ISO
if [ -f "$INSTALLER_DIR/assets/matugen" ]; then chmod +x "$INSTALLER_DIR/assets/matugen"; fi
if [ -f "$INSTALLER_DIR/assets/oh-my-posh" ]; then chmod +x "$INSTALLER_DIR/assets/oh-my-posh"; fi

# --- 3. Clean Old Builds ---
echo -e "\e[33m==> Cleaning previous build artifacts...\e[0m"
rm -rf "$PROFILE_DIR/work"
rm -rf "$PROFILE_DIR/out"
mkdir -p "$PROFILE_DIR/out"

# --- 4. Build the ISO ---
echo -e "\e[32m==> Running mkarchiso...\e[0m"
mkarchiso -v -w "$PROFILE_DIR/work/" -o "$PROFILE_DIR/out/" "$PROFILE_DIR"

# --- 5. Finish ---
if [ $? -eq 0 ]; then
    echo ""
    echo -e "\e[32mSUCCESS: ISO built successfully!\e[0m"
    echo "You can find your new ISO in: $PROFILE_DIR/out/"
    ls -lh "$PROFILE_DIR/out/"*.iso
else
    echo ""
    echo -e "\e[31mERROR: ISO build failed. Check the output above for mkarchiso errors.\e[0m"
    exit 1
fi
