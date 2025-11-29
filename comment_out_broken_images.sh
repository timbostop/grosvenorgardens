#!/bin/bash

# Script to comment out broken image references (images that don't exist locally)
# Usage: ./comment_out_broken_images.sh <post_file>

POST_FILE="$1"

if [ ! -f "$POST_FILE" ]; then
    echo "Error: Post file not found: $POST_FILE"
    exit 1
fi

# Check if post has image references to external/missing images
if ! grep -q '!\[.*\](images/' "$POST_FILE"; then
    exit 0
fi

# Get the directory containing the post
POST_DIR=$(dirname "$POST_FILE")
IMAGES_DIR="$POST_DIR/images"

# If images directory doesn't exist, all image references are broken
if [ ! -d "$IMAGES_DIR" ]; then
    # Create temporary file
    TEMP_FILE=$(mktemp)
    COMMENTED=0

    # Process file line by line
    IN_COMMENT=0
    while IFS= read -r line; do
        # Check if line contains image reference
        if echo "$line" | grep -q '!\[.*\](images/'; then
            # Check if not already commented
            if ! echo "$line" | grep -q '^<!--'; then
                if [ $IN_COMMENT -eq 0 ]; then
                    echo "<!-- Broken image reference:" >> "$TEMP_FILE"
                    IN_COMMENT=1
                    COMMENTED=$((COMMENTED + 1))
                fi
                echo "$line" >> "$TEMP_FILE"
            else
                echo "$line" >> "$TEMP_FILE"
            fi
        else
            # No image reference on this line
            if [ $IN_COMMENT -eq 1 ]; then
                echo "-->" >> "$TEMP_FILE"
                IN_COMMENT=0
            fi
            echo "$line" >> "$TEMP_FILE"
        fi
    done < "$POST_FILE"

    # Close any remaining comment
    if [ $IN_COMMENT -eq 1 ]; then
        echo "-->" >> "$TEMP_FILE"
    fi

    if [ $COMMENTED -gt 0 ]; then
        mv "$TEMP_FILE" "$POST_FILE"
        echo "$COMMENTED"
    else
        rm "$TEMP_FILE"
        echo "0"
    fi
else
    echo "0"
fi
