#!/bin/bash

# Script to restore lost content from posts that had image references processed
# This fixes cases where text was on the same line as ![](images/...) references

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Checking all processed posts for lost content..."
echo ""

FIXED=0
CHECKED=0

# Get list of all markdown files that were modified
git diff --name-only HEAD _posts/**/*.md | while IFS= read -r file; do
    [ -z "$file" ] && continue

    FULL_PATH="$SCRIPT_DIR/$file"
    [ ! -f "$FULL_PATH" ] && continue

    CHECKED=$((CHECKED + 1))

    # Get the original content from git
    ORIGINAL=$(git show "HEAD:$file" 2>/dev/null)
    [ $? -ne 0 ] && continue

    # Check if original had image references on lines with other text
    # Look for pattern: text![...](images/...)text or ![...](images/...)text
    if echo "$ORIGINAL" | grep -q '.\+!\[.*\](images/\|!\[.*\](images/.).\+'; then
        REL_PATH=$(echo "$file" | sed "s|^_posts/||")

        # Create a backup
        BACKUP_DIR="$SCRIPT_DIR/.restore_backups"
        mkdir -p "$BACKUP_DIR/$(dirname "$file")"
        cp "$FULL_PATH" "$BACKUP_DIR/$file"

        # Process the original content line by line
        TEMP_FILE=$(mktemp)

        # First, copy front matter
        awk '/^---$/{c++} c<2{print} c==2{print; exit}' "$FULL_PATH" > "$TEMP_FILE"

        # Now process the original content, replacing image references but keeping surrounding text
        echo "$ORIGINAL" | awk '
        BEGIN { in_frontmatter=0; fm_count=0; }

        /^---$/ {
            fm_count++
            if (fm_count <= 2) {
                in_frontmatter = (fm_count == 1)
                next
            }
        }

        fm_count < 2 { next }

        {
            line = $0

            # Check if line contains image reference
            if (match(line, /!\[[^\]]*\]\(images\/[^)]+\)/)) {
                # Extract parts before and after the image
                img_start = RSTART
                img_length = RLENGTH

                before = substr(line, 1, img_start - 1)
                img_ref = substr(line, img_start, img_length)
                after = substr(line, img_start + img_length)

                # Extract filename
                match(img_ref, /images\/([^)]+)/, arr)
                filename = arr[1]

                # Decode URL encoding
                gsub(/%20/, " ", filename)

                # Output: before text, then HTML image, then after text
                if (before != "") print before

                print "<div class=\"single-image\" style=\"margin: 20px 0;\">"
                print "  <a href=\"/grosvenorgardens/images/" filename "\" target=\"_blank\">"
                print "    <img src=\"/grosvenorgardens/images/" filename "\" alt=\"" filename "\" style=\"max-width: 600px; width: 100%; height: auto;\" loading=\"lazy\" />"
                print "  </a>"
                print "</div>"

                if (after != "") print after
            } else {
                print line
            }
        }
        ' >> "$TEMP_FILE"

        # Replace the file
        mv "$TEMP_FILE" "$FULL_PATH"

        FIXED=$((FIXED + 1))
        echo "[$FIXED] Fixed: $REL_PATH"
    fi
done

echo ""
echo "Checked $CHECKED modified files"
echo "Fixed $FIXED files with lost content"
echo "Backups saved to .restore_backups/"
