#!/bin/bash
# download_robust.sh
# Downloads packages one-by-one to prevent a single failure from stopping the process.

# --- CONFIGURATION ---
REPO_DIR="$HOME/ml4w-iso/airootfs/root/ml4w-repo"
PKG_FILE="$HOME/ml4w-iso/airootfs/root/ml4w-installer/pkglist.txt"
TEMP_DIR="/tmp/ml4w-cache-temp"

# --- SETUP ---
echo ":: Setting up directories..."
mkdir -p "$REPO_DIR"
# Clear and recreate temp dir with 777 permissions (Fixes 'Permission Denied')
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
chmod 777 "$TEMP_DIR"

# Check list
if [ ! -f "$PKG_FILE" ]; then
    echo "!! Error: pkglist.txt not found at $PKG_FILE"
    exit 1
fi

# --- MAIN LOOP ---
echo ":: Reading package list..."
# Read file into an array
mapfile -t PACKAGE_LIST < <(cat "$PKG_FILE" | tr ' ' '\n' | grep -v "^$")

TOTAL=${#PACKAGE_LIST[@]}
CURRENT=0

echo ":: Starting Robust Download ($TOTAL packages)..."

for pkg in "${PACKAGE_LIST[@]}"; do
    ((CURRENT++))

    # Optional: fast skip if we already see the file in repo (rough check)
    # This isn't perfect because of version numbers, but helps on re-runs
    if ls "$REPO_DIR/$pkg-"* &> /dev/null; then
        echo "[$CURRENT/$TOTAL] Skipping $pkg (Found in repo)"
        continue
    fi

    echo "[$CURRENT/$TOTAL] Downloading: $pkg..."

    # Download command
    # -Sw : Download only
    # --cachedir : Use our temp folder (writable by everyone)
    # --noconfirm : Don't ask questions
    # --needed : Don't re-download if it's already in the temp folder
    if sudo pacman -Sw --cachedir "$TEMP_DIR" --noconfirm --needed "$pkg" > /dev/null 2>&1; then

        # Success! Move ANY new .pkg.tar.zst files from temp to repo
        # We use 'mv -n' (no clobber) so we don't overwrite existing good files
        # We redirect stderr to hide "cannot stat" warnings if temp is empty
        mv -n "$TEMP_DIR"/*.pkg.tar.zst "$REPO_DIR/" 2>/dev/null

        # Clean temp so next iteration is clean
        rm -f "$TEMP_DIR"/*.pkg.tar.zst
    else
        echo "!! WARNING: Failed to download $pkg. Skipping..."
        # We do NOT exit. We continue to the next one.
    fi
done

# --- CLEANUP & DB ---
echo "-----------------------------------------------------"
echo ":: Download loop finished."
echo ":: Cleaning up temp folder..."
rm -rf "$TEMP_DIR"

echo ":: Generating Repository Database (This links everything together)..."
cd "$REPO_DIR" || exit
# This adds ALL files in the folder to the DB, ensuring everything is registered
repo-add ml4w_repo.db.tar.gz *.pkg.tar.zst

echo ":: DONE! Your offline repository is ready."
