#!/bin/bash

# Comment out all broken image references across all posts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMENT_SCRIPT="$SCRIPT_DIR/comment_out_broken_images.sh"

chmod +x "$COMMENT_SCRIPT"

echo "Commenting out broken image references..."
echo ""

TOTAL_COMMENTED=0
FILES_MODIFIED=0

# Find all posts with missing images (no images directory)
while IFS= read -r file; do
    REL_PATH=$(echo "$file" | sed "s|$SCRIPT_DIR/||")

    RESULT=$("$COMMENT_SCRIPT" "$file")

    if [ "$RESULT" != "0" ] && [ -n "$RESULT" ]; then
        FILES_MODIFIED=$((FILES_MODIFIED + 1))
        TOTAL_COMMENTED=$((TOTAL_COMMENTED + RESULT))
        echo "[$FILES_MODIFIED] $REL_PATH - Commented out $RESULT image references"
    fi
done < <(find "$SCRIPT_DIR/_posts" -type f -name "*.md")

echo ""
echo "Summary:"
echo "  Files modified: $FILES_MODIFIED"
echo "  Total image references commented out: $TOTAL_COMMENTED"
