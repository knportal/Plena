#!/bin/bash
# Script to open the built watch app folder in Finder

WATCH_APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/Plena-*/Build/Products/Debug-watchos -name "Plena Watch App.app" -type d 2>/dev/null | head -1)

if [ -z "$WATCH_APP_PATH" ]; then
    echo "Watch app not found. Make sure you've built the watch app first."
    echo "Building watch app now..."
    cd "$(dirname "$0")"
    xcodebuild -project Plena.xcodeproj -scheme "Plena Watch App" -destination 'generic/platform=watchOS' build > /dev/null 2>&1
    WATCH_APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/Plena-*/Build/Products/Debug-watchos -name "Plena Watch App.app" -type d 2>/dev/null | head -1)
fi

if [ -n "$WATCH_APP_PATH" ]; then
    echo "Opening watch app folder: $WATCH_APP_PATH"
    open "$(dirname "$WATCH_APP_PATH")"
    echo ""
    echo "The watch app folder is now open in Finder."
    echo "You can drag 'Plena Watch App.app' to Xcode Devices window to install it."
else
    echo "Error: Could not find watch app. Please build it first in Xcode."
fi

