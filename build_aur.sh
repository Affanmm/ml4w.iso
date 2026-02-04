#!/bin/bash
# FORCE SAFE MODE: Use only 2 CPU cores for building
export MAKEFLAGS="-j2"
# Limit Go language builds to 2 cores as well (for nwg-dock)
export GOFLAGS="-p=2"

# --- CONFIGURATION ---
# Path to your ISO repository folder
REPO_DIR="$HOME/ml4w-iso/airootfs/root/ml4w-repo"

# List of AUR packages to build
# I have added the ones you requested + common dependencies
AUR_PACKAGES=(
    "wlogout"
    "nwg-dock-hyprland"
    "hyprshade"
    "grimblast-git"
    "waypaper"
    "python-screeninfo"
    "uwsm"
    "swww"
    "nwg-look"
    "matugen-bin"
    "bibata-cursor-theme"
)

# Create a temporary build directory
BUILD_DIR="$HOME/aur_build_temp"

# --- CHECKS ---
if [ "$EUID" -eq 0 ]; then
    echo "Please do NOT run this script as root/sudo."
    echo "makepkg fails if run as root."
    exit 1
fi

if [ ! -d "$REPO_DIR" ]; then
    echo "Creating repo directory: $REPO_DIR"
    mkdir -p "$REPO_DIR"
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR" || exit

# --- BUILD LOOP ---
echo ":: Starting AUR Build Process..."

for package in "${AUR_PACKAGES[@]}"; do
    if [ -d "$package" ]; then
        rm -rf "$package"
    fi

    echo "-----------------------------------------------------"
    echo ":: Building: $package"
    echo "-----------------------------------------------------"

    # 1. Clone
    git clone "https://aur.archlinux.org/$package.git"

    if [ ! -d "$package" ]; then
        echo "!! Error: Failed to clone $package. Skipping."
        continue
    fi

    cd "$package" || continue

    # 2. Build
    # -s: Install dependencies (requires sudo password during execution)
    # --noconfirm: Don't ask to confirm installs
    # -c: Clean up after build
    if makepkg -s --noconfirm -c; then
        echo ":: Build successful for $package"

        # 3. Move .pkg.tar.zst file to Repo
        mv *.pkg.tar.zst "$REPO_DIR/"
        echo ":: Moved package to $REPO_DIR"
    else
        echo "!! Error: Build failed for $package"
    fi

    # 4. Cleanup
    cd "$BUILD_DIR" || exit
    # rm -rf "$package" # Uncomment to save space, keep commented to debug
done

# --- CLEANUP & FINISH ---
echo "-----------------------------------------------------"
echo ":: All builds finished."
echo ":: Cleaning up temp directory..."
rm -rf "$BUILD_DIR"

echo ":: Generating Database..."
cd "$REPO_DIR" || exit
repo-add ml4w_repo.db.tar.gz *.pkg.tar.zst

echo ":: DONE! Your offline repository is ready."
ls -lh "$REPO_DIR"
