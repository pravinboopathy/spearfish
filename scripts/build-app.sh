#!/bin/bash

# Spearfish App Bundle Build Script (Xcode-based)
# Builds, signs, and notarizes using xcodebuild

set -e

# Configuration
APP_NAME="Spearfish"
BUNDLE_ID="com.spearfish.mac"
SCHEME="Spearfish"
CONFIGURATION="Release"

# Code Signing Configuration
# Set these environment variables or use command-line flags:
#   CODE_SIGN_IDENTITY - Your Developer ID Application certificate name
#   DEVELOPMENT_TEAM - Your Apple Developer Team ID
#   APPLE_ID - Your Apple ID email for notarization
#   APP_PASSWORD - App-specific password for notarization
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-}"
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}"
APPLE_ID="${APPLE_ID:-}"
APP_PASSWORD="${APP_PASSWORD:-}"

# Signing mode
SIGN_APP=false
NOTARIZE_APP=false
USE_AUTOMATIC_SIGNING=false

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
        --auto-sign)
            USE_AUTOMATIC_SIGNING=true
            SIGN_APP=true
            shift
            ;;
        --identity)
            CODE_SIGN_IDENTITY="$2"
            shift 2
            ;;
        --team-id)
            DEVELOPMENT_TEAM="$2"
            shift 2
            ;;
        --apple-id)
            APPLE_ID="$2"
            shift 2
            ;;
        --scheme)
            SCHEME="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --sign                  Sign the app bundle with Developer ID"
            echo "  --notarize              Sign and notarize the app (required for distribution)"
            echo "  --auto-sign             Use automatic code signing (requires team ID)"
            echo "  --identity ID           Code signing identity (e.g., 'Developer ID Application: Name (TEAMID)')"
            echo "  --team-id ID            Apple Developer Team ID"
            echo "  --apple-id EMAIL        Apple ID for notarization"
            echo "  --scheme NAME           Xcode scheme name (default: Spearfish)"
            echo ""
            echo "Environment variables (alternative to flags):"
            echo "  CODE_SIGN_IDENTITY, DEVELOPMENT_TEAM, APPLE_ID, APP_PASSWORD"
            echo ""
            echo "Examples:"
            echo "  # Build without signing"
            echo "  $0"
            echo ""
            echo "  # Build with automatic signing"
            echo "  $0 --sign --auto-sign --team-id ABC123"
            echo ""
            echo "  # Build with manual signing"
            echo "  $0 --sign --identity \"Developer ID Application: John Doe (ABC123)\""
            echo ""
            echo "  # Build, sign, and notarize"
            echo "  $0 --notarize --team-id ABC123 --apple-id john@example.com"
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
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_DIR="$BUILD_DIR"
APP_BUNDLE="$EXPORT_DIR/$APP_NAME.app"
RESOURCES_DIR="$PROJECT_DIR/Resources"
PACKAGE_SWIFT="$PROJECT_DIR/Package.swift"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Verify Package.swift exists
if [ ! -f "$PACKAGE_SWIFT" ]; then
    echo_error "Package.swift not found at $PACKAGE_SWIFT"
    exit 1
fi

# Clean previous build
echo_info "Cleaning previous build..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Validate signing configuration
if [ "$SIGN_APP" = true ]; then
    echo_info "Code signing enabled"
    
    if [ "$USE_AUTOMATIC_SIGNING" = true ]; then
        echo_info "Using automatic code signing"
        
        if [ -z "$DEVELOPMENT_TEAM" ]; then
            echo_error "Automatic signing requires --team-id or DEVELOPMENT_TEAM environment variable"
            exit 1
        fi
        
        echo_info "Team ID: $DEVELOPMENT_TEAM"
    else
        echo_info "Using manual code signing"
        
        if [ -z "$CODE_SIGN_IDENTITY" ]; then
            echo_error "Manual signing requires --identity or CODE_SIGN_IDENTITY environment variable"
            echo ""
            echo "Available identities:"
            security find-identity -v -p codesigning
            exit 1
        fi
        
        # Verify the certificate exists
        if ! security find-identity -v -p codesigning | grep -q "$CODE_SIGN_IDENTITY"; then
            echo_error "Certificate not found: $CODE_SIGN_IDENTITY"
            echo ""
            echo "Available identities:"
            security find-identity -v -p codesigning
            exit 1
        fi
        
        echo_info "Code signing identity: $CODE_SIGN_IDENTITY"
    fi
fi

# Build and archive
echo_info "Building and archiving..."
cd "$PROJECT_DIR"

XCODEBUILD_ARGS=(
    -scheme "$SCHEME"
    -configuration "$CONFIGURATION"
    -destination "platform=macOS"
    -archivePath "$ARCHIVE_PATH"
)

# Add signing parameters if enabled
if [ "$SIGN_APP" = true ]; then
    if [ -n "$DEVELOPMENT_TEAM" ]; then
        XCODEBUILD_ARGS+=(DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM")
    fi
    
    if [ "$USE_AUTOMATIC_SIGNING" = true ]; then
        XCODEBUILD_ARGS+=(CODE_SIGN_STYLE="Automatic")
    else
        XCODEBUILD_ARGS+=(CODE_SIGN_STYLE="Manual")
        if [ -n "$CODE_SIGN_IDENTITY" ]; then
            XCODEBUILD_ARGS+=(CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY")
        fi
    fi
    
    # Enable hardened runtime for distribution
    XCODEBUILD_ARGS+=(ENABLE_HARDENED_RUNTIME="YES")
    XCODEBUILD_ARGS+=(OTHER_CODE_SIGN_FLAGS="--timestamp")
fi

xcodebuild archive "${XCODEBUILD_ARGS[@]}"

if [ $? -ne 0 ]; then
    echo_error "Archive failed"
    exit 1
fi

echo_info "Archive created successfully"

# Extract binary from archive
ARCHIVED_BINARY="$ARCHIVE_PATH/Products/usr/local/bin/$APP_NAME"

if [ ! -f "$ARCHIVED_BINARY" ]; then
    echo_error "Archived binary not found at $ARCHIVED_BINARY"
    exit 1
fi

# Create app bundle structure
echo_info "Creating app bundle structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary to app bundle
echo_info "Copying binary to app bundle..."
cp "$ARCHIVED_BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
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

echo_info "App bundle created successfully"

# Code Signing
if [ "$SIGN_APP" = true ]; then
    echo_info "Code signing app bundle..."
    
    # Determine entitlements path
    ENTITLEMENTS_PATH=""
    if [ -f "$RESOURCES_DIR/Spearfish.entitlements" ]; then
        ENTITLEMENTS_PATH="$RESOURCES_DIR/Spearfish.entitlements"
        echo_info "Using entitlements file: $ENTITLEMENTS_PATH"
    fi
    
    # Sign the main executable
    echo_info "Signing executable..."
    CODESIGN_ARGS=(
        --force
        --options runtime
        --timestamp
    )
    
    if [ -n "$CODE_SIGN_IDENTITY" ]; then
        CODESIGN_ARGS+=(--sign "$CODE_SIGN_IDENTITY")
    else
        # Use automatic signing - find Developer ID
        DEVELOPER_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | awk -F'"' '{print $2}')
        if [ -z "$DEVELOPER_ID" ]; then
            echo_error "No Developer ID Application certificate found"
            security find-identity -v -p codesigning
            exit 1
        fi
        CODESIGN_ARGS+=(--sign "$DEVELOPER_ID")
        echo_info "Auto-selected identity: $DEVELOPER_ID"
    fi
    
    if [ -n "$ENTITLEMENTS_PATH" ]; then
        CODESIGN_ARGS+=(--entitlements "$ENTITLEMENTS_PATH")
    fi
    
    codesign "${CODESIGN_ARGS[@]}" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    
    # Sign any frameworks/libraries if present
    if [ -d "$APP_BUNDLE/Contents/Frameworks" ]; then
        echo_info "Signing frameworks..."
        find "$APP_BUNDLE/Contents/Frameworks" -type f -perm +111 | while read -r framework; do
            codesign --force --options runtime --timestamp \
                --sign "${CODE_SIGN_IDENTITY:-$DEVELOPER_ID}" "$framework"
        done
    fi
    
    # Sign the app bundle itself
    echo_info "Signing app bundle..."
    BUNDLE_CODESIGN_ARGS=(
        --force
        --options runtime
        --timestamp
    )
    
    if [ -n "$CODE_SIGN_IDENTITY" ]; then
        BUNDLE_CODESIGN_ARGS+=(--sign "$CODE_SIGN_IDENTITY")
    else
        BUNDLE_CODESIGN_ARGS+=(--sign "$DEVELOPER_ID")
    fi
    
    if [ -n "$ENTITLEMENTS_PATH" ]; then
        BUNDLE_CODESIGN_ARGS+=(--entitlements "$ENTITLEMENTS_PATH")
    fi
    
    codesign "${BUNDLE_CODESIGN_ARGS[@]}" "$APP_BUNDLE"
    
    # Verify signature
    echo_info "Verifying code signature..."
    codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
    
    if [ $? -eq 0 ]; then
        echo_info "Code signature verified successfully"
        
        # Display signature info
        echo_info "Signature details:"
        codesign -dvv "$APP_BUNDLE" 2>&1 | grep -E "Authority|TeamIdentifier|Identifier"
    else
        echo_error "Code signature verification failed"
        exit 1
    fi
fi

# Notarization
if [ "$NOTARIZE_APP" = true ]; then
    echo_info "Notarization enabled"
    
    # Validate notarization credentials
    if [ -z "$APPLE_ID" ]; then
        echo_error "Notarization requires --apple-id or APPLE_ID environment variable"
        exit 1
    fi
    
    if [ -z "$DEVELOPMENT_TEAM" ]; then
        echo_error "Notarization requires --team-id or DEVELOPMENT_TEAM environment variable"
        exit 1
    fi
    
    if [ -z "$APP_PASSWORD" ]; then
        echo_error "APP_PASSWORD environment variable not set"
        echo "Create an app-specific password at https://appleid.apple.com"
        exit 1
    fi
    
    # Create a ZIP for notarization
    NOTARIZE_ZIP="$BUILD_DIR/$APP_NAME-notarize.zip"
    echo_info "Creating ZIP for notarization..."
    ditto -c -k --keepParent "$APP_BUNDLE" "$NOTARIZE_ZIP"
    
    # Submit for notarization
    echo_info "Submitting for notarization (this may take several minutes)..."
    
    # Create a temporary file to capture output
    NOTARIZE_LOG="$BUILD_DIR/notarize_output.log"
    
    # Submit and capture output while still showing it to the user
    xcrun notarytool submit "$NOTARIZE_ZIP" \
        --apple-id "$APPLE_ID" \
        --team-id "$DEVELOPMENT_TEAM" \
        --password "$APP_PASSWORD" \
        --wait 2>&1 | tee "$NOTARIZE_LOG"
    
    NOTARIZE_STATUS=${PIPESTATUS[0]}
    
    # Extract submission ID from output
    SUBMISSION_ID=$(grep -E "^\s*id:" "$NOTARIZE_LOG" | awk '{print $2}')
    
    if [ -n "$SUBMISSION_ID" ]; then
        echo_info "Submission ID: $SUBMISSION_ID"
    fi
    
    # Clean up log file
    rm -f "$NOTARIZE_LOG"
    
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
        if [ -n "$SUBMISSION_ID" ]; then
            echo "To view the notarization log, run:"
            echo "  xcrun notarytool log $SUBMISSION_ID --apple-id $APPLE_ID --team-id $DEVELOPMENT_TEAM"
        else
            echo "To view the notarization log, find your submission ID and run:"
            echo "  xcrun notarytool log <submission-id> --apple-id $APPLE_ID --team-id $DEVELOPMENT_TEAM"
        fi
        exit 1
    fi
fi

# Done
echo ""
echo_info "Build complete!"
echo_info "App bundle created at: $APP_BUNDLE"

# Display binary info
BINARY_PATH="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
echo ""
echo "Binary info:"
lipo -info "$BINARY_PATH"
file "$BINARY_PATH"

if [ "$SIGN_APP" = true ]; then
    echo ""
    echo_info "App is signed with Developer ID"
fi

if [ "$NOTARIZE_APP" = true ]; then
    echo_info "App is notarized and ready for distribution"
fi

echo ""
echo "To run the app:"
echo "  open \"$APP_BUNDLE\""
echo ""
echo "To create a DMG for distribution:"
echo "  ./scripts/create-dmg.sh"

if [ "$SIGN_APP" = false ]; then
    echo ""
    echo "To sign for distribution:"
    echo "  # With automatic signing:"
    echo "  $0 --sign --auto-sign --team-id YOUR_TEAM_ID"
    echo ""
    echo "  # With manual signing:"
    echo "  $0 --sign --identity \"Developer ID Application: Your Name (TEAM_ID)\""
    echo ""
    echo "To sign and notarize:"
    echo "  $0 --notarize --team-id YOUR_TEAM_ID --apple-id your@email.com"
fi

















