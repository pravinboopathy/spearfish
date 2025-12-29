#!/bin/bash

# Spearfish App Bundle Build Script (Xcode IDE-equivalent)
# Builds release-ready signed and notarized builds for distribution
# Matches Xcode IDE's Archive → Distribute App → Developer ID workflow

set -e

# Configuration
APP_NAME="Spearfish"
SCHEME="Spearfish"
CONFIGURATION="Release"

# Code Signing Configuration (set via environment or flags)
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}"
APPLE_ID="${APPLE_ID:-}"
APP_PASSWORD="${APP_PASSWORD:-}"

# Notarization mode
NOTARIZE_APP=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --notarize)
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
            echo "This script builds release-ready signed builds for distribution."
            echo "It matches what Xcode IDE does when you Archive and Distribute with Developer ID."
            echo ""
            echo "Options:"
            echo "  --notarize              Notarize the app (recommended for distribution)"
            echo "  --team-id ID            Apple Developer Team ID (required)"
            echo "  --apple-id EMAIL        Apple ID for notarization (required with --notarize)"
            echo "  --scheme NAME           Xcode scheme name (default: Spearfish)"
            echo ""
            echo "Environment variables:"
            echo "  DEVELOPMENT_TEAM        Your Apple Developer Team ID"
            echo "  APPLE_ID                Your Apple ID email for notarization"
            echo "  APP_PASSWORD            App-specific password for notarization"
            echo ""
            echo "Examples:"
            echo "  # Build and sign (like Xcode IDE Archive → Distribute)"
            echo "  $0 --team-id ABC123"
            echo ""
            echo "  # Build, sign, and notarize (recommended for distribution)"
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

# Validate required configuration
if [ -z "$DEVELOPMENT_TEAM" ]; then
    echo_error "Team ID is required. Use --team-id or set DEVELOPMENT_TEAM environment variable"
    echo "Run with --help for usage information"
    exit 1
fi

echo_info "Building release-ready signed app for distribution"
echo_info "Team ID: $DEVELOPMENT_TEAM"

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

# Build for distribution (matches Xcode IDE Archive action)
xcodebuild archive \
    -project "$XCODEPROJ" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "generic/platform=macOS" \
    -archivePath "$ARCHIVE_PATH" \
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
    CODE_SIGN_STYLE="Automatic" \
    ONLY_ACTIVE_ARCH="NO"

if [ $? -ne 0 ]; then
    echo_error "Archive failed"
    exit 1
fi

echo_info "Archive created successfully"

# Export the archive (matches Xcode IDE Distribute App → Developer ID)
echo_info "Exporting archive with Developer ID signing..."

# Create ExportOptions.plist (matches Xcode IDE's export settings)
EXPORT_OPTIONS="$BUILD_DIR/ExportOptions.plist"
cat > "$EXPORT_OPTIONS" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>destination</key>
    <string>export</string>
    <key>method</key>
    <string>developer-id</string>
    <key>signingCertificate</key>
    <string>Developer ID Application</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
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

echo ""
echo_info "App is signed with Developer ID"

if [ "$NOTARIZE_APP" = true ]; then
    echo_info "App is notarized and ready for distribution"
    echo ""
    echo "Distribution checklist:"
    echo "  ✓ Built in Release configuration"
    echo "  ✓ Signed with Developer ID Application certificate"
    echo "  ✓ Hardened Runtime enabled"
    echo "  ✓ Notarized by Apple"
    echo "  ✓ Notarization ticket stapled"
else
    echo_warn "App is NOT notarized - users will see security warnings"
    echo ""
    echo "To notarize for distribution, run:"
    echo "  $0 --notarize --team-id $DEVELOPMENT_TEAM --apple-id your@email.com"
fi

echo ""
echo "To test the app:"
echo "  open \"$APP_BUNDLE\""
echo ""
echo "To create a DMG for distribution:"
echo "  ./scripts/create-dmg.sh"





