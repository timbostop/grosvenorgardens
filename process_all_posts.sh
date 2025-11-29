#!/bin/bash

# Process all posts in _posts directory
# This script finds all markdown files and runs replace_gallery.sh on each

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POSTS_DIR="$SCRIPT_DIR/_posts"
REPLACE_SCRIPT="$SCRIPT_DIR/replace_gallery.sh"

if [ ! -f "$REPLACE_SCRIPT" ]; then
    echo "Error: replace_gallery.sh not found at $REPLACE_SCRIPT"
    exit 1
fi

if [ ! -d "$POSTS_DIR" ]; then
    echo "Error: _posts directory not found at $POSTS_DIR"
    exit 1
fi

echo "Starting to process all posts in $POSTS_DIR"
echo "=========================================="
echo ""

# Counters
TOTAL_FILES=0
PROCESSED_FILES=0
SKIPPED_FILES=0

# Find all markdown files in _posts
while IFS= read -r post_file; do
    TOTAL_FILES=$((TOTAL_FILES + 1))

    # Get relative path for display
    REL_PATH=$(echo "$post_file" | sed "s|$SCRIPT_DIR/||")

    echo "[$TOTAL_FILES] Processing: $REL_PATH"

    # Run the replace script
    OUTPUT=$("$REPLACE_SCRIPT" "$post_file" 2>&1)
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        # Check if anything was actually processed
        if echo "$OUTPUT" | grep -q "No \[gallery\] tag or image references found"; then
            SKIPPED_FILES=$((SKIPPED_FILES + 1))
            echo "    → Skipped (no gallery tags or image references)"
        else
            PROCESSED_FILES=$((PROCESSED_FILES + 1))
            echo "    → Success"
            # Show details if images were processed
            echo "$OUTPUT" | grep -E "Replaced|Moved" | sed 's/^/    /'
        fi
    else
        echo "    → Error: $OUTPUT"
    fi

    echo ""
done < <(find "$POSTS_DIR" -type f -name "*.md")

echo "=========================================="
echo "Processing complete!"
echo ""
echo "Summary:"
echo "  Total files found: $TOTAL_FILES"
echo "  Files processed:   $PROCESSED_FILES"
echo "  Files skipped:     $SKIPPED_FILES"
echo ""
echo "Images are now in: $SCRIPT_DIR/images"
