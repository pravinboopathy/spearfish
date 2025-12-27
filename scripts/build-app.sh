#!/bin/bash

# Spearfish App Bundle Build Script
# Creates a .app bundle from the SPM executable

set -e

# Configuration
APP_NAME="Spearfish"
BUNDLE_ID="com.spearfish.mac"
VERSION="1.0.0"

# Code Signing Configuration
# Set these environment variables or replace with your values:
#   DEVELOPER_ID - Your Developer ID Application certificate name
#   APPLE_ID - Your Apple ID email for notarization
#   APPLE_TEAM_ID - Your Apple Developer Team ID
#   APP_PASSWORD - App-specific password for notarization (create at appleid.apple.com)
DEVELOPER_ID="${DEVELOPER_ID:-}"
APPLE_ID="${APPLE_ID:-}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
APP_PASSWORD="${APP_PASSWORD:-}"

# Signing flags
SIGN_APP=false
NOTARIZE_APP=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --sign)
            SIGN_APP=true
            shift
            ;;
        --notarize)
            SIGN_APP=true
            NOTARIZE_APP=true
            shift
            ;;
        --developer-id)
            DEVELOPER_ID="$2"
            shift 2
            ;;
        --apple-id)
            APPLE_ID="$2"
            shift 2
            ;;
        --team-id)
            APPLE_TEAM_ID="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --sign              Sign the app bundle with Developer ID"
            echo "  --notarize          Sign and notarize the app (required for distribution)"
            echo "  --developer-id ID   Developer ID Application certificate name"
            echo "  --apple-id EMAIL    Apple ID for notarization"
            echo "  --team-id ID        Apple Developer Team ID"
            echo ""
            echo "Environment variables (alternative to flags):"
            echo "  DEVELOPER_ID, APPLE_ID, APPLE_TEAM_ID, APP_PASSWORD"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

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

# Copy entitlements
ENTITLEMENTS_PATH=""
if [ -f "$RESOURCES_DIR/Spearfish.entitlements" ]; then
    cp "$RESOURCES_DIR/Spearfish.entitlements" "$BUILD_DIR/Spearfish.entitlements"
    ENTITLEMENTS_PATH="$BUILD_DIR/Spearfish.entitlements"
fi

# Code Signing
if [ "$SIGN_APP" = true ]; then
    echo_info "Code signing enabled"

    # Validate Developer ID
    if [ -z "$DEVELOPER_ID" ]; then
        echo_error "Developer ID not set. Use --developer-id or set DEVELOPER_ID env var."
        echo "Available identities:"
        security find-identity -v -p codesigning
        exit 1
    fi

    # Verify the certificate exists
    if ! security find-identity -v -p codesigning | grep -q "$DEVELOPER_ID"; then
        echo_error "Certificate not found: $DEVELOPER_ID"
        echo "Available identities:"
        security find-identity -v -p codesigning
        exit 1
    fi

    echo_info "Signing with: $DEVELOPER_ID"

    # Sign the main executable
    echo_info "Signing executable..."
    if [ -n "$ENTITLEMENTS_PATH" ]; then
        codesign --force --options runtime --timestamp \
            --entitlements "$ENTITLEMENTS_PATH" \
            --sign "$DEVELOPER_ID" \
            "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    else
        codesign --force --options runtime --timestamp \
            --sign "$DEVELOPER_ID" \
            "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    fi

    # Sign any frameworks/libraries if present
    if [ -d "$APP_BUNDLE/Contents/Frameworks" ]; then
        echo_info "Signing frameworks..."
        find "$APP_BUNDLE/Contents/Frameworks" -type f -perm +111 | while read -r framework; do
            codesign --force --options runtime --timestamp \
                --sign "$DEVELOPER_ID" "$framework"
        done
    fi

    # Sign the app bundle itself
    echo_info "Signing app bundle..."
    if [ -n "$ENTITLEMENTS_PATH" ]; then
        codesign --force --options runtime --timestamp \
            --entitlements "$ENTITLEMENTS_PATH" \
            --sign "$DEVELOPER_ID" \
            "$APP_BUNDLE"
    else
        codesign --force --options runtime --timestamp \
            --sign "$DEVELOPER_ID" \
            "$APP_BUNDLE"
    fi

    # Verify signature
    echo_info "Verifying signature..."
    codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

    if [ $? -eq 0 ]; then
        echo_info "Code signing successful!"
    else
        echo_error "Code signing verification failed!"
        exit 1
    fi
fi

# Notarization
if [ "$NOTARIZE_APP" = true ]; then
    echo_info "Notarization enabled"

    # Validate notarization credentials
    if [ -z "$APPLE_ID" ] || [ -z "$APPLE_TEAM_ID" ]; then
        echo_error "Notarization requires APPLE_ID and APPLE_TEAM_ID"
        echo "Set via --apple-id and --team-id flags or environment variables"
        exit 1
    fi

    if [ -z "$APP_PASSWORD" ]; then
        echo_error "APP_PASSWORD not set. Create an app-specific password at https://appleid.apple.com"
        echo "Then set the APP_PASSWORD environment variable"
        exit 1
    fi

    # Create a ZIP for notarization
    NOTARIZE_ZIP="$BUILD_DIR/$APP_NAME-notarize.zip"
    echo_info "Creating ZIP for notarization..."
    ditto -c -k --keepParent "$APP_BUNDLE" "$NOTARIZE_ZIP"

    # Submit for notarization
    echo_info "Submitting for notarization (this may take several minutes)..."
    xcrun notarytool submit "$NOTARIZE_ZIP" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$APP_PASSWORD" \
        --wait

    NOTARIZE_STATUS=$?

    # Clean up ZIP
    rm -f "$NOTARIZE_ZIP"

    if [ $NOTARIZE_STATUS -eq 0 ]; then
        echo_info "Notarization successful!"

        # Staple the notarization ticket
        echo_info "Stapling notarization ticket..."
        xcrun stapler staple "$APP_BUNDLE"

        if [ $? -eq 0 ]; then
            echo_info "Stapling successful!"
        else
            echo_warn "Stapling failed. The app is notarized but users may see a delay on first launch."
        fi
    else
        echo_error "Notarization failed!"
        echo "Check the notarization log for details:"
        echo "  xcrun notarytool log <submission-id> --apple-id $APPLE_ID --team-id $APPLE_TEAM_ID"
        exit 1
    fi
fi

# Done
echo ""
echo_info "Build complete!"
echo_info "App bundle created at: $APP_BUNDLE"

if [ "$SIGN_APP" = true ]; then
    echo_info "App is signed with Developer ID"
fi

if [ "$NOTARIZE_APP" = true ]; then
    echo_info "App is notarized and ready for distribution"
fi

echo ""
echo "To run the app:"
echo "  open $APP_BUNDLE"
echo ""
echo "To create a DMG for distribution:"
echo "  ./scripts/create-dmg.sh"

if [ "$SIGN_APP" = false ]; then
    echo ""
    echo "To sign for distribution, run:"
    echo "  $0 --sign --developer-id \"Developer ID Application: Your Name (TEAM_ID)\""
    echo ""
    echo "To sign and notarize:"
    echo "  $0 --notarize --developer-id \"Developer ID Application: Your Name (TEAM_ID)\" \\"
    echo "     --apple-id your@email.com --team-id YOUR_TEAM_ID"
fi
