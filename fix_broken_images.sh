#!/bin/bash

# Script to find and comment out broken image references
# Usage: ./fix_broken_images.sh <post_file>

POST_FILE="$1"

if [ ! -f "$POST_FILE" ]; then
    echo "Error: Post file not found: $POST_FILE"
    exit 1
fi

# Get the root directory (where the script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES_DIR="$SCRIPT_DIR/images"

# Check if the post contains any image references
if ! grep -q '/grosvenorgardens/images/' "$POST_FILE"; then
    exit 0
fi

# Create a temporary file for output
OUTPUT_FILE=$(mktemp)

# Counters
BROKEN_COUNT=0
IN_BROKEN_BLOCK=0

# Process the file line by line
while IFS= read -r line; do
    # Check if line contains an image reference
    if echo "$line" | grep -q '/grosvenorgardens/images/'; then
        # Extract the image filename from the line
        IMG_PATH=$(echo "$line" | grep -o '/grosvenorgardens/images/[^"]*' | head -1)

        if [ -n "$IMG_PATH" ]; then
            # Get just the filename
            IMG_FILE=$(basename "$IMG_PATH")
            # Decode URL encoding for file check
            IMG_FILE_DECODED=$(echo "$IMG_FILE" | sed 's/%20/ /g')
            LOCAL_PATH="$IMAGES_DIR/$IMG_FILE_DECODED"

            # Check if the file exists
            if [ ! -f "$LOCAL_PATH" ]; then
                # File doesn't exist - start commenting out if not already in a commented block
                if [ $IN_BROKEN_BLOCK -eq 0 ]; then
                    echo "<!-- Missing image: $IMG_FILE" >> "$OUTPUT_FILE"
                    BROKEN_COUNT=$((BROKEN_COUNT + 1))
                    IN_BROKEN_BLOCK=1
                fi
                echo "$line" >> "$OUTPUT_FILE"
            else
                # File exists - close comment block if we were in one
                if [ $IN_BROKEN_BLOCK -eq 1 ]; then
                    echo "-->" >> "$OUTPUT_FILE"
                    IN_BROKEN_BLOCK=0
                fi
                echo "$line" >> "$OUTPUT_FILE"
            fi
        else
            echo "$line" >> "$OUTPUT_FILE"
        fi
    else
        # Line doesn't contain image reference
        # Check if we need to close a comment block
        if [ $IN_BROKEN_BLOCK -eq 1 ]; then
            # Check if this is a closing tag for the image block
            if echo "$line" | grep -q '</div>'; then
                echo "$line" >> "$OUTPUT_FILE"
                echo "-->" >> "$OUTPUT_FILE"
                IN_BROKEN_BLOCK=0
            else
                echo "$line" >> "$OUTPUT_FILE"
            fi
        else
            echo "$line" >> "$OUTPUT_FILE"
        fi
    fi
done < "$POST_FILE"

# Close any remaining open comment block
if [ $IN_BROKEN_BLOCK -eq 1 ]; then
    echo "-->" >> "$OUTPUT_FILE"
fi

# Only replace the file if we found broken images
if [ $BROKEN_COUNT -gt 0 ]; then
    mv "$OUTPUT_FILE" "$POST_FILE"
    echo "$BROKEN_COUNT"
else
    rm "$OUTPUT_FILE"
    echo "0"
fi
