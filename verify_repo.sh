#!/bin/bash
REPO_DIR="$HOME/ml4w-iso/airootfs/root/ml4w-repo"
DB_FILE="$REPO_DIR/ml4w_repo.db.tar.gz"

echo ":: Verifying Repository Integrity..."

if [ ! -f "$DB_FILE" ]; then
    echo "!! CRITICAL: Database file missing!"
    exit 1
fi

# Get list of packages the DB *thinks* it has
# We use tar to peek inside the DB file
DB_ENTRIES=$(tar -tf "$DB_FILE" | grep "/desc" | cut -d'/' -f1)

MISSING=0
for entry in $DB_ENTRIES; do
    # entry is like "wlogout-1.1.1-1"
    # We look for a file starting with that name
    if ! ls "$REPO_DIR/$entry"*.pkg.tar.zst &> /dev/null; then
        echo "!! ERROR: DB lists '$entry' but FILE IS MISSING in folder!"
        ((MISSING++))
    fi
done

if [ "$MISSING" -eq 0 ]; then
    echo ":: SUCCESS: All database entries have matching files."
    echo ":: You are ready to build."
else
    echo "!! FAIL: $MISSING packages are missing files. Re-run download script."
fi
