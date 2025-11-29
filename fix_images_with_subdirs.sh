#!/bin/bash

# Script to properly fix image references using subdirectory organization
# Each post's images go into /images/YYYY-MM/post-slug/ subdirectory
# This prevents filename conflicts naturally

POST_FILE="$1"

if [ ! -f "$POST_FILE" ]; then
    echo "Error: Post file not found: $POST_FILE"
    exit 1
fi

# Get the directory containing the post
POST_DIR=$(dirname "$POST_FILE")
IMAGES_DIR="$POST_DIR/images"

if [ ! -d "$IMAGES_DIR" ]; then
    echo "No images directory found at $IMAGES_DIR, skipping"
    exit 0
fi

# Get the root directory (where the script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_IMAGES_DIR="$SCRIPT_DIR/images"

# Extract date and slug from post path
# Path format: _posts/2008/05/2008-05-29-continual-improvement/post.md
# Extract: 2008-05 and continual-improvement

# Get the parent directory name (contains date and slug)
POST_PARENT=$(basename "$POST_DIR")
# Extract date: first 7 chars (YYYY-MM)
DATE_PREFIX=$(echo "$POST_PARENT" | cut -c1-7)
# Extract slug: everything after YYYY-MM-DD- (11th char onwards)
SLUG=$(echo "$POST_PARENT" | cut -c12-)

if [ -z "$DATE_PREFIX" ] || [ -z "$SLUG" ]; then
    echo "Error: Could not extract date/slug from $POST_PARENT"
    exit 1
fi

echo "Processing: $POST_FILE"
echo "  Date: $DATE_PREFIX"
echo "  Slug: $SLUG"

# Create target directory
TARGET_DIR="$ROOT_IMAGES_DIR/$DATE_PREFIX/$SLUG"
mkdir -p "$TARGET_DIR"

# Copy all images to target directory
IMAGES_COPIED=0
for img in "$IMAGES_DIR"/*; do
    if [ -f "$img" ]; then
        IMG_NAME=$(basename "$img")
        cp "$img" "$TARGET_DIR/$IMG_NAME"
        IMAGES_COPIED=$((IMAGES_COPIED + 1))
    fi
done

echo "  Copied $IMAGES_COPIED images to $TARGET_DIR"

# Now process the markdown file
TEMP_FILE="${POST_FILE}.tmp"
> "$TEMP_FILE"

# Variables to track state
IN_FRONT_MATTER=0
FRONT_MATTER_COUNT=0
HAS_GALLERY=0
HAS_IMAGE_REFS=0

# Check if file has [gallery] or image references (handle escaped \[gallery\])
if grep -qE '\\?\[gallery\\?\]' "$POST_FILE"; then
    HAS_GALLERY=1
fi

if grep -qE '!\[.*\]\(images/' "$POST_FILE"; then
    HAS_IMAGE_REFS=1
fi

# Read file line by line
while IFS= read -r line; do
    # Track front matter
    if [ "$line" = "---" ]; then
        FRONT_MATTER_COUNT=$((FRONT_MATTER_COUNT + 1))
        echo "$line" >> "$TEMP_FILE"
        continue
    fi

    # If we're in front matter, just pass through
    if [ $FRONT_MATTER_COUNT -lt 2 ]; then
        echo "$line" >> "$TEMP_FILE"
        continue
    fi

    # Check for [gallery] tag (handle escaped \[gallery\])
    if echo "$line" | grep -qE '\\?\[gallery\\?\]'; then
        echo "  Replacing [gallery] tag"
        # Build gallery HTML
        echo "<div class=\"gallery\" style=\"display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 10px; margin: 20px 0;\">" >> "$TEMP_FILE"

        for img in "$IMAGES_DIR"/*; do
            if [ -f "$img" ]; then
                IMG_NAME=$(basename "$img")
                # URL encode spaces
                IMG_PATH="/images/$DATE_PREFIX/$SLUG/${IMG_NAME// /%20}"

                echo "  <div class=\"gallery-item\">" >> "$TEMP_FILE"
                echo "    <a href=\"$IMG_PATH\" target=\"_blank\">" >> "$TEMP_FILE"
                echo "      <img src=\"$IMG_PATH\" alt=\"$IMG_NAME\" style=\"width: 100%; height: 200px; object-fit: cover;\" loading=\"lazy\" />" >> "$TEMP_FILE"
                echo "    </a>" >> "$TEMP_FILE"
                echo "  </div>" >> "$TEMP_FILE"
            fi
        done

        echo "</div>" >> "$TEMP_FILE"
        continue
    fi

    # Check for inline image references: ![alt](images/file.jpg)
    if echo "$line" | grep -qE '!\[.*\]\(images/'; then
        # Extract text before and after image reference
        # This handles inline images correctly

        # Check if line has multiple images or inline text
        TEMP_LINE="$line"

        # Process each image reference on the line
        while echo "$TEMP_LINE" | grep -qE '!\[.*\]\(images/[^)]+\)'; do
            # Extract everything before the image
            BEFORE=$(echo "$TEMP_LINE" | sed -E 's/(.*)(!\[.*\]\(images\/[^)]+\))(.*)/\1/')

            # Extract the image reference itself
            IMG_REF=$(echo "$TEMP_LINE" | sed -E 's/.*!\[.*\]\(images\/([^)]+)\).*/\1/')

            # Extract everything after the image
            AFTER=$(echo "$TEMP_LINE" | sed -E 's/(.*)(!\[.*\]\(images\/[^)]+\))(.*)/\3/')

            # Output text before image (if any)
            if [ -n "$BEFORE" ]; then
                echo -n "$BEFORE" >> "$TEMP_FILE"
            fi

            # Output HTML for image
            # URL encode spaces in filename
            IMG_PATH="/images/$DATE_PREFIX/$SLUG/${IMG_REF// /%20}"

            echo "" >> "$TEMP_FILE"
            echo "<div class=\"single-image\" style=\"margin: 20px 0;\">" >> "$TEMP_FILE"
            echo "  <a href=\"$IMG_PATH\" target=\"_blank\">" >> "$TEMP_FILE"
            echo "    <img src=\"$IMG_PATH\" alt=\"$IMG_REF\" style=\"max-width: 600px; width: 100%; height: auto;\" loading=\"lazy\" />" >> "$TEMP_FILE"
            echo "  </a>" >> "$TEMP_FILE"
            echo "</div>" >> "$TEMP_FILE"
            echo "" >> "$TEMP_FILE"

            # Continue with the rest of the line
            TEMP_LINE="$AFTER"
        done

        # Output any remaining text
        if [ -n "$TEMP_LINE" ]; then
            echo "$TEMP_LINE" >> "$TEMP_FILE"
        fi
        continue
    fi

    # Pass through all other lines unchanged
    echo "$line" >> "$TEMP_FILE"

done < "$POST_FILE"

# Replace original file with processed version
mv "$TEMP_FILE" "$POST_FILE"

echo "  Done processing $POST_FILE"
