#!/bin/bash

# Add apology messages to all posts with missing images

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIND_SCRIPT="$SCRIPT_DIR/find_broken_images.sh"
ADD_SCRIPT="$SCRIPT_DIR/add_missing_image_notice.sh"

chmod +x "$ADD_SCRIPT"

COUNT=0

echo "Adding apology messages to posts with missing images..."
echo ""

while IFS= read -r file; do
    REL_PATH=$(echo "$file" | sed "s|$SCRIPT_DIR/||")
    RESULT=$("$ADD_SCRIPT" "$file")

    if [ "$RESULT" = "Added apology message" ]; then
        COUNT=$((COUNT + 1))
        echo "[$COUNT] $REL_PATH"
    fi
done < <("$FIND_SCRIPT")

echo ""
echo "Added apology messages to $COUNT posts"
