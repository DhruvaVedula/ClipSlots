#!/bin/bash

# Script to copy the latest ClipSlots build to /Applications

set -e

echo "🔍 Finding latest ClipSlots build..."

# Find the most recently built ClipSlots.app
BUILD_DIR=$(find ~/Library/Developer/Xcode/DerivedData -name "ClipSlots.app" -type d -path "*/Build/Products/Debug/*" 2>/dev/null | head -1)

if [ -z "$BUILD_DIR" ]; then
    echo "❌ ERROR: Could not find ClipSlots.app in DerivedData"
    echo "   Make sure you've built the project in Xcode first (⌘B)"
    exit 1
fi

echo "✅ Found build at: $BUILD_DIR"
echo ""

# Kill any running instance
echo "🛑 Stopping any running ClipSlots instances..."
killall ClipSlots 2>/dev/null || true
sleep 1

# Copy to Applications
echo "📦 Copying to /Applications/ClipSlots.app..."
rm -rf /Applications/ClipSlots.app
cp -R "$BUILD_DIR" /Applications/ClipSlots.app

echo "✅ Successfully copied to /Applications/ClipSlots.app"
echo ""
echo "📋 Next steps:"
echo "   1. Run the app: open /Applications/ClipSlots.app"
echo "   2. Grant Accessibility permissions when prompted"
echo "   3. Test your hotkeys!"

