#!/bin/bash

# Add apology message to posts with missing images
# Usage: ./add_missing_image_notice.sh <post_file>

POST_FILE="$1"

if [ ! -f "$POST_FILE" ]; then
    echo "Error: Post file not found: $POST_FILE"
    exit 1
fi

# Check if post already has the apology message
if grep -q "Unfortunately, some images from this post are missing" "$POST_FILE"; then
    echo "Already has apology message"
    exit 0
fi

# Find the line number where the front matter ends (second ---)
END_LINE=$(grep -n "^---$" "$POST_FILE" | sed -n '2p' | cut -d: -f1)

if [ -z "$END_LINE" ]; then
    echo "Error: Could not find end of front matter"
    exit 1
fi

# Create temporary file
TEMP_FILE=$(mktemp)

# Copy everything up to and including the end of front matter
head -n "$END_LINE" "$POST_FILE" > "$TEMP_FILE"

# Add blank line and apology message
echo "" >> "$TEMP_FILE"
echo "*Unfortunately, some images from this post are missing - they were sadly lost during the blog migration.*" >> "$TEMP_FILE"

# Add the rest of the file
tail -n +$((END_LINE + 1)) "$POST_FILE" >> "$TEMP_FILE"

# Replace original file
mv "$TEMP_FILE" "$POST_FILE"

echo "Added apology message"
