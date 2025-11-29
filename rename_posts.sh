#!/bin/bash

# Script to rename index.md files to match their parent directory name

# Find all index.md files in output/posts
find output/posts -name "index.md" -type f | while read -r filepath; do
    # Get the directory containing the index.md
    dir=$(dirname "$filepath")

    # Get the parent directory name (e.g., 2013-05-06-fun-in-the-jungle)
    folder_name=$(basename "$dir")

    # Construct the new filename
    new_filepath="$dir/$folder_name.md"

    # Rename the file
    mv "$filepath" "$new_filepath"

    echo "Renamed: $filepath -> $new_filepath"
done

echo "Done! All index.md files have been renamed."
