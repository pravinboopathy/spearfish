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
EXPORT_OPTIONS_PLIST="$BUILD_DIR/ExportOptions.plist"
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

# Create ExportOptions.plist
create_export_options() {
    local METHOD="$1"  # none, developer-id, or app-store
    
    echo_info "Creating export options..."
    
    cat > "$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$METHOD</string>
EOF

    if [ "$SIGN_APP" = true ]; then
        if [ -n "$DEVELOPMENT_TEAM" ]; then
            cat >> "$EXPORT_OPTIONS_PLIST" <<EOF
    <key>teamID</key>
    <string>$DEVELOPMENT_TEAM</string>
EOF
        fi
        
        if [ "$USE_AUTOMATIC_SIGNING" = false ] && [ -n "$CODE_SIGN_IDENTITY" ]; then
            cat >> "$EXPORT_OPTIONS_PLIST" <<EOF
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>$CODE_SIGN_IDENTITY</string>
EOF
        else
            cat >> "$EXPORT_OPTIONS_PLIST" <<EOF
    <key>signingStyle</key>
    <string>automatic</string>
EOF
        fi
    fi
    
    cat >> "$EXPORT_OPTIONS_PLIST" <<EOF
    <key>destination</key>
    <string>export</string>
    <key>compileBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <false/>
</dict>
</plist>
EOF
}

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

# Create export options plist
if [ "$SIGN_APP" = true ]; then
    create_export_options "developer-id"
else
    create_export_options "none"
fi

# Export the archive
echo_info "Exporting app bundle..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

if [ $? -ne 0 ]; then
    echo_error "Export failed"
    exit 1
fi

# Verify app bundle was created
if [ ! -d "$APP_BUNDLE" ]; then
    echo_error "App bundle not found at $APP_BUNDLE"
    exit 1
fi

echo_info "Export successful"

# Verify signature if signed
if [ "$SIGN_APP" = true ]; then
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
    xcrun notarytool submit "$NOTARIZE_ZIP" \
        --apple-id "$APPLE_ID" \
        --team-id "$DEVELOPMENT_TEAM" \
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
        echo "To view the notarization log, find your submission ID and run:"
        echo "  xcrun notarytool log <submission-id> --apple-id $APPLE_ID --team-id $DEVELOPMENT_TEAM"
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
