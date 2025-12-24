#!/bin/bash

echo "🚀 ClipSlots Quick Test"
echo "======================"
echo ""

# Check if app exists
if [ ! -d "/Applications/ClipSlots.app" ]; then
    echo "❌ ClipSlots.app not found in /Applications"
    echo "   Run: ./copy_to_applications.sh first"
    exit 1
fi

echo "✅ ClipSlots.app found"
echo ""

# Kill any existing instance
echo "🛑 Stopping any running instances..."
killall ClipSlots 2>/dev/null || true
sleep 1

# Launch app
echo "🚀 Launching ClipSlots..."
open /Applications/ClipSlots.app

echo ""
echo "✅ App launched!"
echo ""
echo "📋 Next steps:"
echo "   1. Check menubar for 'CS' icon"
echo "   2. Click the icon to open menu"
echo "   3. Test hotkeys:"
echo "      - Ctrl+Cmd+Q = Store selected text to slot Q"
echo "      - Ctrl+Cmd+Shift+Q = Paste from slot Q"
echo "      - Ctrl+Cmd+Option+Q = Capture screenshot to slot Q"
echo ""
echo "   4. Grant permissions if prompted:"
echo "      - Accessibility (for copy/paste)"
echo "      - Screen Recording (for screenshots)"
echo ""
echo "   5. Check Console.app for debug output"
