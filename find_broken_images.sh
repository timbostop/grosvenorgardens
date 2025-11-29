#!/bin/bash

# Find posts that have image references but no local images directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find all posts with image references
grep -rl '!\[.*\](images/' "$SCRIPT_DIR/_posts" | while IFS= read -r file; do
  # Check if the images directory exists for this post
  dir=$(dirname "$file")
  if [ ! -d "$dir/images" ]; then
    echo "$file"
  fi
done
