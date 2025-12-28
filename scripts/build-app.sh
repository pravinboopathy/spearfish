#!/bin/bash

# Spearfish App Bundle Build Script (Xcode-based)
# Builds, signs, and notarizes using xcodebuild archive/export

set -e

# Configuration
APP_NAME="Spearfish"
SCHEME="Spearfish"
CONFIGURATION="Release"

# Code Signing Configuration (set via environment or flags)
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}"
APPLE_ID="${APPLE_ID:-}"
APP_PASSWORD="${APP_PASSWORD:-}"

# Build modes
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
            echo "  --team-id ID            Apple Developer Team ID"
            echo "  --apple-id EMAIL        Apple ID for notarization"
            echo "  --scheme NAME           Xcode scheme name (default: Spearfish)"
            echo ""
            echo "Environment variables:"
            echo "  DEVELOPMENT_TEAM        Your Apple Developer Team ID"
            echo "  APPLE_ID                Your Apple ID email for notarization"
            echo "  APP_PASSWORD            App-specific password for notarization"
            echo ""
            echo "Examples:"
            echo "  # Build without signing (local development)"
            echo "  $0"
            echo ""
            echo "  # Build and sign"
            echo "  $0 --sign --team-id ABC123"
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
XCODEPROJ="$PROJECT_DIR/Spearfish.xcodeproj"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Verify Xcode project exists
if [ ! -d "$XCODEPROJ" ]; then
    echo_error "Xcode project not found at $XCODEPROJ"
    echo "Run 'xcodegen generate' to create it from project.yml"
    exit 1
fi

# Clean previous build
echo_info "Cleaning previous build..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Validate signing configuration
if [ "$SIGN_APP" = true ]; then
    echo_info "Code signing enabled"

    if [ -z "$DEVELOPMENT_TEAM" ]; then
        echo_error "Signing requires --team-id or DEVELOPMENT_TEAM environment variable"
        exit 1
    fi

    echo_info "Team ID: $DEVELOPMENT_TEAM"
fi

if [ "$NOTARIZE_APP" = true ]; then
    echo_info "Notarization enabled"

    if [ -z "$APPLE_ID" ]; then
        echo_error "Notarization requires --apple-id or APPLE_ID environment variable"
        exit 1
    fi

    if [ -z "$APP_PASSWORD" ]; then
        echo_error "APP_PASSWORD environment variable not set"
        echo "Create an app-specific password at https://appleid.apple.com"
        exit 1
    fi
fi

# Build and archive
echo_info "Building and archiving..."
cd "$PROJECT_DIR"

XCODEBUILD_ARGS=(
    -project "$XCODEPROJ"
    -scheme "$SCHEME"
    -configuration "$CONFIGURATION"
    -destination "generic/platform=macOS"
    -archivePath "$ARCHIVE_PATH"
)

if [ "$SIGN_APP" = true ]; then
    XCODEBUILD_ARGS+=(
        DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM"
        CODE_SIGN_STYLE="Automatic"
    )
else
    # Build without signing for local development
    XCODEBUILD_ARGS+=(
        CODE_SIGN_IDENTITY="-"
        CODE_SIGNING_REQUIRED="NO"
        CODE_SIGNING_ALLOWED="NO"
    )
fi

xcodebuild archive "${XCODEBUILD_ARGS[@]}"

if [ $? -ne 0 ]; then
    echo_error "Archive failed"
    exit 1
fi

echo_info "Archive created successfully"

# Export the archive
echo_info "Exporting archive..."

if [ "$SIGN_APP" = true ]; then
    # Create ExportOptions.plist for signed export
    EXPORT_OPTIONS="$BUILD_DIR/ExportOptions.plist"
    cat > "$EXPORT_OPTIONS" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>$DEVELOPMENT_TEAM</string>
</dict>
</plist>
EOF

    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_DIR" \
        -exportOptionsPlist "$EXPORT_OPTIONS"

    if [ $? -ne 0 ]; then
        echo_error "Export failed"
        exit 1
    fi

    echo_info "Export completed successfully"

    # Verify signature
    echo_info "Verifying code signature..."
    codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

    if [ $? -eq 0 ]; then
        echo_info "Code signature verified successfully"
        echo_info "Signature details:"
        codesign -dvv "$APP_BUNDLE" 2>&1 | grep -E "Authority|TeamIdentifier|Identifier"
    else
        echo_error "Code signature verification failed"
        exit 1
    fi
else
    # For unsigned builds, just copy the app from the archive
    echo_info "Extracting app from archive (unsigned)..."
    cp -R "$ARCHIVE_PATH/Products/Applications/$APP_NAME.app" "$EXPORT_DIR/"
fi

# Notarization
if [ "$NOTARIZE_APP" = true ]; then
    echo_info "Starting notarization..."

    # Create a ZIP for notarization
    NOTARIZE_ZIP="$BUILD_DIR/$APP_NAME-notarize.zip"
    echo_info "Creating ZIP for notarization..."
    ditto -c -k --keepParent "$APP_BUNDLE" "$NOTARIZE_ZIP"

    # Submit for notarization
    echo_info "Submitting for notarization (this may take several minutes)..."

    NOTARIZE_LOG="$BUILD_DIR/notarize_output.log"

    xcrun notarytool submit "$NOTARIZE_ZIP" \
        --apple-id "$APPLE_ID" \
        --team-id "$DEVELOPMENT_TEAM" \
        --password "$APP_PASSWORD" \
        --wait 2>&1 | tee "$NOTARIZE_LOG"

    NOTARIZE_STATUS=${PIPESTATUS[0]}

    # Extract submission ID
    SUBMISSION_ID=$(grep -E "^\s*id:" "$NOTARIZE_LOG" | head -1 | awk '{print $2}')

    if [ -n "$SUBMISSION_ID" ]; then
        echo_info "Submission ID: $SUBMISSION_ID"
    fi

    rm -f "$NOTARIZE_LOG"
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
    echo "  $0 --sign --team-id YOUR_TEAM_ID"
    echo ""
    echo "To sign and notarize:"
    echo "  $0 --notarize --team-id YOUR_TEAM_ID --apple-id your@email.com"
fi
