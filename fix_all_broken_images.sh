#!/bin/bash

# Process all posts to find and comment out broken image links

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POSTS_DIR="$SCRIPT_DIR/_posts"
FIX_SCRIPT="$SCRIPT_DIR/fix_broken_images.sh"

if [ ! -f "$FIX_SCRIPT" ]; then
    echo "Error: fix_broken_images.sh not found"
    exit 1
fi

chmod +x "$FIX_SCRIPT"

echo "Finding and commenting out broken image references..."
echo "=========================================="
echo ""

# Counters
TOTAL_FILES=0
FILES_WITH_BROKEN=0
TOTAL_BROKEN=0

# Find all markdown files in _posts
while IFS= read -r post_file; do
    TOTAL_FILES=$((TOTAL_FILES + 1))

    # Run the fix script
    BROKEN=$("$FIX_SCRIPT" "$post_file")

    if [ "$BROKEN" != "0" ] && [ -n "$BROKEN" ]; then
        FILES_WITH_BROKEN=$((FILES_WITH_BROKEN + 1))
        TOTAL_BROKEN=$((TOTAL_BROKEN + BROKEN))

        # Get relative path for display
        REL_PATH=$(echo "$post_file" | sed "s|$SCRIPT_DIR/||")
        echo "[$FILES_WITH_BROKEN] $REL_PATH"
        echo "    → Commented out $BROKEN broken image reference(s)"
    fi
done < <(find "$POSTS_DIR" -type f -name "*.md")

echo ""
echo "=========================================="
echo "Processing complete!"
echo ""
echo "Summary:"
echo "  Total files checked: $TOTAL_FILES"
echo "  Files with broken images: $FILES_WITH_BROKEN"
echo "  Total broken images commented out: $TOTAL_BROKEN"
