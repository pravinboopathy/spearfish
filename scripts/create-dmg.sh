#!/bin/bash

# Spearfish DMG Creation Script
# Creates a distributable DMG from the app bundle

set -e

# Configuration
APP_NAME="Spearfish"
DMG_NAME="Spearfish"
VOLUME_NAME="Spearfish"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$DMG_NAME.dmg"
DMG_TEMP="$BUILD_DIR/$DMG_NAME-temp.dmg"
STAGING_DIR="$BUILD_DIR/dmg-staging"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo_error "App bundle not found at $APP_BUNDLE"
    echo_error "Run ./scripts/build-app.sh first"
    exit 1
fi

# Clean previous DMG
echo_info "Cleaning previous DMG..."
rm -f "$DMG_PATH"
rm -f "$DMG_TEMP"
rm -rf "$STAGING_DIR"

# Create staging directory
echo_info "Creating staging directory..."
mkdir -p "$STAGING_DIR"

# Copy app bundle to staging
echo_info "Copying app bundle..."
cp -R "$APP_BUNDLE" "$STAGING_DIR/"

# Create Applications symlink
echo_info "Creating Applications symlink..."
ln -s /Applications "$STAGING_DIR/Applications"

# Calculate DMG size (app size + 10MB buffer)
APP_SIZE=$(du -sm "$APP_BUNDLE" | cut -f1)
DMG_SIZE=$((APP_SIZE + 10))

echo_info "Creating DMG (${DMG_SIZE}MB)..."

# Create temporary DMG
hdiutil create \
    -srcfolder "$STAGING_DIR" \
    -volname "$VOLUME_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size ${DMG_SIZE}m \
    "$DMG_TEMP"

# Mount the temporary DMG
echo_info "Mounting DMG for customization..."
MOUNT_DIR="/Volumes/$VOLUME_NAME"

# Unmount if already mounted
if [ -d "$MOUNT_DIR" ]; then
    hdiutil detach "$MOUNT_DIR" -quiet || true
fi

hdiutil attach "$DMG_TEMP" -mountpoint "$MOUNT_DIR" -quiet

# Set custom DMG window appearance using AppleScript
echo_info "Setting DMG window appearance..."
osascript << EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {400, 100, 900, 400}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 80
        set position of item "$APP_NAME.app" of container window to {120, 140}
        set position of item "Applications" of container window to {380, 140}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Sync and unmount
sync
hdiutil detach "$MOUNT_DIR" -quiet

# Convert to compressed read-only DMG
echo_info "Converting to compressed DMG..."
hdiutil convert "$DMG_TEMP" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_PATH"

# Cleanup
rm -f "$DMG_TEMP"
rm -rf "$STAGING_DIR"

# Get DMG info
DMG_FINAL_SIZE=$(du -h "$DMG_PATH" | cut -f1)

echo ""
echo_info "DMG created successfully!"
echo_info "Location: $DMG_PATH"
echo_info "Size: $DMG_FINAL_SIZE"
echo ""
echo "To install:"
echo "  1. Open $DMG_PATH"
echo "  2. Drag $APP_NAME.app to Applications"
echo "  3. Eject the disk image"
echo ""
echo "Note: Since this is an unsigned app, users will need to:"
echo "  - Right-click -> Open on first launch, OR"
echo "  - Allow in System Preferences -> Privacy & Security"
