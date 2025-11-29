#!/bin/bash

# Script to replace [gallery] tags and ![](images/...) references with HTML
# Also moves images to /images folder at root
# Usage: ./replace_gallery.sh <post_file>

POST_FILE="$1"

if [ ! -f "$POST_FILE" ]; then
    echo "Error: Post file not found: $POST_FILE"
    exit 1
fi

# Get the directory containing the post
POST_DIR=$(dirname "$POST_FILE")
IMAGES_DIR="$POST_DIR/images"

if [ ! -d "$IMAGES_DIR" ]; then
    echo "Warning: No images directory found at $IMAGES_DIR"
    exit 0
fi

# Get the root directory (where the script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_IMAGES_DIR="$SCRIPT_DIR/images"

# Create root images directory if it doesn't exist
mkdir -p "$ROOT_IMAGES_DIR"

# Check if we need to process this file
HAS_GALLERY=0
HAS_IMAGE_REFS=0

if grep -q '\\\[gallery\\\]\|[[]gallery[]]' "$POST_FILE"; then
    HAS_GALLERY=1
fi

if grep -q '!\[\](images/' "$POST_FILE"; then
    HAS_IMAGE_REFS=1
fi

if [ $HAS_GALLERY -eq 0 ] && [ $HAS_IMAGE_REFS -eq 0 ]; then
    echo "No [gallery] tag or image references found in $POST_FILE"
    exit 0
fi

# Counter for moved images
IMAGES_MOVED=0

# Function to move image and return the new filename
move_image() {
    local source_path="$1"
    local img_name=$(basename "$source_path")
    local target_path="$ROOT_IMAGES_DIR/$img_name"

    # If target already exists, check if it's the same file
    if [ -f "$target_path" ]; then
        # Check if files are identical
        if cmp -s "$source_path" "$target_path"; then
            # Files are identical, no need to move
            echo "$img_name"
            return 0
        else
            # Files differ, create unique name with post date prefix
            # Extract date from post directory path (YYYY/MM or YYYY-MM)
            local date_prefix=$(echo "$POST_DIR" | grep -o '[0-9]\{4\}/[0-9]\{2\}' | tr '/' '-')
            if [ -z "$date_prefix" ]; then
                date_prefix=$(date +%Y%m%d-%H%M%S)
            fi

            # Create new filename: date-originalname.ext
            local base_name="${img_name%.*}"
            local extension="${img_name##*.}"
            local new_name="${date_prefix}-${base_name}.${extension}"
            target_path="$ROOT_IMAGES_DIR/$new_name"

            # Copy to new location
            cp "$source_path" "$target_path"
            IMAGES_MOVED=$((IMAGES_MOVED + 1))
            echo "$new_name"
            return 0
        fi
    else
        # Target doesn't exist, just copy it
        cp "$source_path" "$target_path"
        IMAGES_MOVED=$((IMAGES_MOVED + 1))
        echo "$img_name"
        return 0
    fi
}

# If we have a gallery tag, build the gallery HTML and move images
GALLERY_FILE=""
if [ $HAS_GALLERY -eq 1 ]; then
    # Find all images in the images directory
    IMAGES=$(find "$IMAGES_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | sort)

    if [ -z "$IMAGES" ]; then
        echo "No images found in $IMAGES_DIR for gallery"
    else
        # Create a temporary file for the gallery HTML
        GALLERY_FILE=$(mktemp)

        # Build the HTML gallery in the temporary file
        echo '<div class="gallery" style="display: flex; flex-wrap: wrap; gap: 10px; justify-content: flex-start;">' > "$GALLERY_FILE"

        while IFS= read -r img; do
            [ -z "$img" ] && continue
            IMG_NAME=$(basename "$img")

            # Move image and get final filename
            FINAL_NAME=$(move_image "$img")

            IMG_PATH="/grosvenorgardens/images/${FINAL_NAME}"

            # Add each image to the gallery
            cat >> "$GALLERY_FILE" << EOF
  <div class="gallery-item" style="flex: 0 0 auto;">
    <a href="${IMG_PATH}" target="_blank">
      <img src="${IMG_PATH}" alt="${FINAL_NAME}" style="width: 200px; height: auto; object-fit: cover;" loading="lazy" />
    </a>
  </div>
EOF
        done <<< "$IMAGES"

        echo '</div>' >> "$GALLERY_FILE"
    fi
fi

# Create output file
OUTPUT_FILE=$(mktemp)

# Process the file line by line
GALLERY_REPLACED=0
IMAGE_REFS_REPLACED=0

while IFS= read -r line; do
    # Check for gallery tag
    if echo "$line" | grep -q '\\\[gallery\\\]\|[[]gallery[]]'; then
        if [ -n "$GALLERY_FILE" ] && [ -f "$GALLERY_FILE" ]; then
            cat "$GALLERY_FILE"
            GALLERY_REPLACED=1
        fi
    # Check for image reference pattern: ![](images/...)
    elif echo "$line" | grep -q '!\[\](images/'; then
        # Extract the image filename from the line
        # Pattern: ![](images/filename.jpg)
        IMG_REF=$(echo "$line" | sed -n 's/.*!\[\](images\/\([^)]*\)).*/\1/p')

        if [ -n "$IMG_REF" ]; then
            # Decode URL encoding for file operations
            IMG_FILE=$(echo "$IMG_REF" | sed 's/%20/ /g')
            SOURCE_PATH="$IMAGES_DIR/$IMG_FILE"

            # Move image and get final filename
            if [ -f "$SOURCE_PATH" ]; then
                FINAL_NAME=$(move_image "$SOURCE_PATH")

                # Build the image path
                IMG_PATH="/grosvenorgardens/images/${FINAL_NAME}"

                # Replace with HTML img tag (600px width for single images)
                echo "<div class=\"single-image\" style=\"margin: 20px 0;\">"
                echo "  <a href=\"${IMG_PATH}\" target=\"_blank\">"
                echo "    <img src=\"${IMG_PATH}\" alt=\"${FINAL_NAME}\" style=\"max-width: 600px; width: 100%; height: auto;\" loading=\"lazy\" />"
                echo "  </a>"
                echo "</div>"
                IMAGE_REFS_REPLACED=$((IMAGE_REFS_REPLACED + 1))
            else
                echo "Warning: Image not found: $SOURCE_PATH" >&2
                echo "$line"
            fi
        else
            echo "$line"
        fi
    else
        echo "$line"
    fi
done < "$POST_FILE" > "$OUTPUT_FILE"

# Replace the original file
mv "$OUTPUT_FILE" "$POST_FILE"

# Clean up
if [ -n "$GALLERY_FILE" ] && [ -f "$GALLERY_FILE" ]; then
    rm "$GALLERY_FILE"
fi

# Report results
echo "Successfully processed $POST_FILE"
if [ $GALLERY_REPLACED -eq 1 ]; then
    IMAGE_COUNT=$(find "$IMAGES_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) 2>/dev/null | wc -l | tr -d ' ')
    echo "  - Replaced [gallery] tag with $IMAGE_COUNT images"
fi
if [ $IMAGE_REFS_REPLACED -gt 0 ]; then
    echo "  - Replaced $IMAGE_REFS_REPLACED individual image references"
fi
echo "  - Moved/copied $IMAGES_MOVED images to $ROOT_IMAGES_DIR"
