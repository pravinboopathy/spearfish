#!/bin/bash

# Spearfish App Bundle Build Script
# Creates a .app bundle from the SPM executable

set -e

# Configuration
APP_NAME="Spearfish"
BUNDLE_ID="com.spearfish.mac"
VERSION="1.0.0"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
RESOURCES_DIR="$PROJECT_DIR/Resources"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Clean previous build
echo_info "Cleaning previous build..."
rm -rf "$APP_BUNDLE"
mkdir -p "$BUILD_DIR"

# Build release binary
echo_info "Building release binary..."
cd "$PROJECT_DIR"
swift build -c release

# Determine architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    BINARY_PATH="$PROJECT_DIR/.build/arm64-apple-macosx/release/$APP_NAME"
else
    BINARY_PATH="$PROJECT_DIR/.build/x86_64-apple-macosx/release/$APP_NAME"
fi

if [ ! -f "$BINARY_PATH" ]; then
    echo_error "Binary not found at $BINARY_PATH"
    exit 1
fi

# Create app bundle structure
echo_info "Creating app bundle structure..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
echo_info "Copying binary..."
cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Info.plist
echo_info "Copying Info.plist..."
if [ -f "$RESOURCES_DIR/Info.plist" ]; then
    cp "$RESOURCES_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
else
    echo_error "Info.plist not found at $RESOURCES_DIR/Info.plist"
    exit 1
fi

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Function to convert image to icns
create_icns() {
    local SOURCE_IMAGE="$1"
    local ICNS_PATH="$2"
    local ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"

    echo_info "Creating icon from $SOURCE_IMAGE..."

    # Create iconset directory
    rm -rf "$ICONSET_DIR"
    mkdir -p "$ICONSET_DIR"

    # Generate all required icon sizes
    # Using sips which is available on all macOS systems
    local SIZES=(16 32 128 256 512)

    for SIZE in "${SIZES[@]}"; do
        sips -z $SIZE $SIZE "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_${SIZE}x${SIZE}.png" > /dev/null 2>&1
        # Create @2x version
        local SIZE_2X=$((SIZE * 2))
        if [ $SIZE_2X -le 1024 ]; then
            sips -z $SIZE_2X $SIZE_2X "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_${SIZE}x${SIZE}@2x.png" > /dev/null 2>&1
        fi
    done

    # Create 512@2x (1024x1024)
    sips -z 1024 1024 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null 2>&1

    # Convert iconset to icns
    iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"

    # Cleanup
    rm -rf "$ICONSET_DIR"

    echo_info "Icon created successfully"
}

# Handle app icon
ICON_CREATED=false

# Check for various icon formats
for EXT in icns png jpg jpeg pdf svg; do
    ICON_SOURCE="$RESOURCES_DIR/AppIcon.$EXT"
    if [ -f "$ICON_SOURCE" ]; then
        if [ "$EXT" = "icns" ]; then
            # Already in icns format, just copy
            echo_info "Copying existing .icns icon..."
            cp "$ICON_SOURCE" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
            ICON_CREATED=true
        elif [ "$EXT" = "svg" ]; then
            # SVG needs special handling
            echo_warn "SVG icons require conversion. Attempting with rsvg-convert..."
            if command -v rsvg-convert &> /dev/null; then
                # Convert SVG to PNG first
                TMP_PNG="$BUILD_DIR/tmp_icon.png"
                rsvg-convert -w 1024 -h 1024 "$ICON_SOURCE" -o "$TMP_PNG"
                create_icns "$TMP_PNG" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
                rm -f "$TMP_PNG"
                ICON_CREATED=true
            else
                echo_warn "rsvg-convert not found. Install librsvg (brew install librsvg) or provide a PNG icon."
            fi
        else
            # PNG, JPG, JPEG, PDF - use sips
            create_icns "$ICON_SOURCE" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
            ICON_CREATED=true
        fi
        break
    fi
done

if [ "$ICON_CREATED" = false ]; then
    echo_warn "No app icon found. Place your icon at Resources/AppIcon.png"
    echo_warn "The app will work but won't have a custom icon."
fi

# Copy entitlements (for reference, not embedded in unsigned builds)
if [ -f "$RESOURCES_DIR/Spearfish.entitlements" ]; then
    cp "$RESOURCES_DIR/Spearfish.entitlements" "$BUILD_DIR/Spearfish.entitlements"
fi

# Done
echo ""
echo_info "Build complete!"
echo_info "App bundle created at: $APP_BUNDLE"
echo ""
echo "To run the app:"
echo "  open $APP_BUNDLE"
echo ""
echo "To create a DMG for distribution:"
echo "  ./scripts/create-dmg.sh"
