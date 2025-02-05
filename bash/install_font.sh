#!/bin/bash

# Define the source font file path
SOURCE_FONT_PATH="/Users/josevigil/repos/SmallFFmpegLocal/assets/fonts/futura.ttf"

# Define the target font directory (use ~/Library/Fonts for user-specific installation)
TARGET_FONT_DIR="$HOME/Library/Fonts"

# Ensure the font directory exists
echo "Creating font directory at $TARGET_FONT_DIR..."
mkdir -p "$TARGET_FONT_DIR"

# Copy the font file to the target directory
echo "Copying font file to $TARGET_FONT_DIR..."
cp "$SOURCE_FONT_PATH" "$TARGET_FONT_DIR/"

# Check if fonts.conf exists, create a new one if it doesn't
FONT_CONFIG_PATH="$HOME/.config/fontconfig/fonts.conf"
if [ ! -f "$FONT_CONFIG_PATH" ]; then
  echo "Creating fonts.conf file..."
  mkdir -p "$(dirname "$FONT_CONFIG_PATH")"
  cat <<EOF > "$FONT_CONFIG_PATH"
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
    <dir>$TARGET_FONT_DIR</dir>
</fontconfig>
EOF
fi

# Rebuild font cache
echo "Rebuilding font cache..."
fc-cache -v -f "$TARGET_FONT_DIR"

# Verify font availability
echo "Verifying font availability..."
fc-list | grep futura.ttf

echo "Font installation complete."
