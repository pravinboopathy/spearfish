#!/bin/bash

# Spearfish Release Script
# Creates a new release with updated version, builds DMG, and publishes to GitHub

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INFO_PLIST="$PROJECT_DIR/Resources/Info.plist"
BUILD_DIR="$PROJECT_DIR/build"

# Check for version argument
if [ -z "$1" ]; then
    echo_error "Usage: ./scripts/release.sh <version>"
    echo "  Example: ./scripts/release.sh 1.0.0"
    echo ""
    echo "Current version: $(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$INFO_PLIST")"
    exit 1
fi

VERSION="$1"

# Validate version format (semver)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo_error "Invalid version format: $VERSION"
    echo "  Use semantic versioning: major.minor.patch (e.g., 1.0.0)"
    exit 1
fi

# Check for gh CLI
if ! command -v gh &> /dev/null; then
    echo_error "GitHub CLI (gh) not found. Install with: brew install gh"
    exit 1
fi

# Check gh auth
if ! gh auth status &> /dev/null; then
    echo_error "Not authenticated with GitHub. Run: gh auth login"
    exit 1
fi

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo_warn "You have uncommitted changes:"
    git status --short
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if tag already exists
if git rev-parse "v$VERSION" >/dev/null 2>&1; then
    echo_error "Tag v$VERSION already exists"
    exit 1
fi

echo_info "Creating release v$VERSION"
echo ""

# Get current version for reference
CURRENT_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$INFO_PLIST")
CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$INFO_PLIST")
NEW_BUILD=$((CURRENT_BUILD + 1))

echo "  Current: v$CURRENT_VERSION (build $CURRENT_BUILD)"
echo "  New:     v$VERSION (build $NEW_BUILD)"
echo ""

# Update Info.plist
echo_info "Updating Info.plist..."
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD" "$INFO_PLIST"

# Build
echo_info "Building app bundle..."
"$SCRIPT_DIR/build-app.sh" --notarize

echo_info "Creating DMG..."
"$SCRIPT_DIR/create-dmg.sh"

# Get release notes
echo ""
echo_info "Enter release notes (press Ctrl+D when done, or leave empty for default):"
NOTES=$(cat 2>/dev/null || true)

if [ -z "$NOTES" ]; then
    NOTES="## What's New in v$VERSION

- Bug fixes and improvements"
fi

# Commit and tag
echo ""
echo_info "Committing changes..."
cd "$PROJECT_DIR"
git add Resources/Info.plist
git commit -m "Release v$VERSION"

echo_info "Creating tag v$VERSION..."
git tag "v$VERSION"

# Push
echo_info "Pushing to origin..."
git push origin main --tags

# Create GitHub release
echo_info "Creating GitHub release..."
gh release create "v$VERSION" \
    --title "Spearfish v$VERSION" \
    --notes "$NOTES" \
    "$BUILD_DIR/Spearfish.dmg"

echo ""
echo_info "Release v$VERSION published successfully!"
echo ""
gh release view "v$VERSION" --web 2>/dev/null || echo "View at: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/releases/tag/v$VERSION"
