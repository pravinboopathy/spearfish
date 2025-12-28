#!/bin/bash

# Spearfish Development Script
# Quick build and run for local testing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
XCODEPROJ="$PROJECT_DIR/Spearfish.xcodeproj"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/Build/Products/Debug/Spearfish.app"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }

# Check if Xcode project exists
if [ ! -d "$XCODEPROJ" ]; then
    echo "Xcode project not found. Generating from project.yml..."
    xcodegen generate --spec "$PROJECT_DIR/project.yml"
fi

# Build
echo_info "Building..."
xcodebuild -project "$XCODEPROJ" \
    -scheme Spearfish \
    -configuration Debug \
    -derivedDataPath "$BUILD_DIR" \
    build \
    2>&1 | grep -E "(error:|warning:|BUILD|Compiling)" || true

# Check if build succeeded
if [ ! -d "$APP_BUNDLE" ]; then
    echo "Build failed - app bundle not found"
    exit 1
fi

echo_info "Build complete: $APP_BUNDLE"

# Run if requested
if [[ "$1" == "--run" || "$1" == "-r" ]]; then
    echo_info "Launching Spearfish..."
    open "$APP_BUNDLE"
elif [[ "$1" == "--run-fg" || "$1" == "-f" ]]; then
    echo_info "Running Spearfish in foreground..."
    "$APP_BUNDLE/Contents/MacOS/Spearfish"
else
    echo ""
    echo "To run:"
    echo "  $0 --run      # Launch app"
    echo "  $0 --run-fg   # Run in foreground (see logs)"
fi
