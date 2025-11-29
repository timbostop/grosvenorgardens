#!/bin/bash

# Wrapper script to process all posts with the subdirectory image fix

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting to process all posts..."
echo "======================================"

TOTAL=0
PROCESSED=0
SKIPPED=0

# Find all markdown files in _posts
find _posts -name "*.md" -type f | sort | while read post_file; do
    TOTAL=$((TOTAL + 1))

    # Check if post has images directory
    POST_DIR=$(dirname "$post_file")
    if [ -d "$POST_DIR/images" ]; then
        "$SCRIPT_DIR/fix_images_with_subdirs.sh" "$post_file"
        PROCESSED=$((PROCESSED + 1))
    else
        echo "Skipping (no images): $post_file"
        SKIPPED=$((SKIPPED + 1))
    fi
done

echo "======================================"
echo "Processing complete!"
echo "Total posts found: $TOTAL"
echo "Posts processed: $PROCESSED"
echo "Posts skipped: $SKIPPED"
