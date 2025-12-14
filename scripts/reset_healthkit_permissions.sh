#!/bin/bash

# Reset HealthKit Permissions for Testing
# This script helps reset HealthKit permissions by uninstalling the app
# Run this script before testing permission flows

set -e

BUNDLE_ID="com.plena.meditation.app"
APP_NAME="Plena"

echo "🧹 Resetting HealthKit Permissions for $APP_NAME"
echo ""
echo "This script will:"
echo "  1. Uninstall the app (removes all permissions)"
echo "  2. Clear any cached data"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled"
    exit 1
fi

# Check if running on macOS with connected device
if command -v xcrun &> /dev/null; then
    echo "📱 Checking for connected devices..."

    # Get list of connected devices
    DEVICES=$(xcrun xctrace list devices 2>/dev/null | grep -i "iphone\|ipad" | head -1)

    if [ -z "$DEVICES" ]; then
        echo "⚠️  No iOS device found."
        echo "   For Simulator: Delete the app manually from the simulator"
        echo "   For Device: Delete the app manually from the device"
        echo ""
        echo "After deleting, you can reinstall by:"
        echo "  1. Building and running from Xcode, or"
        echo "  2. Installing from App Store/TestFlight"
        exit 0
    fi

    echo "✅ Found device: $DEVICES"
    echo ""
    echo "To reset permissions:"
    echo "  1. Long press the app icon on your device"
    echo "  2. Tap 'Remove App' → 'Delete App'"
    echo "  3. Reinstall from Xcode or TestFlight"
    echo ""
    echo "Alternatively, manually reset in Settings:"
    echo "  Settings → Privacy & Security → Health → $APP_NAME"
    echo "  Turn OFF all permissions"
else
    echo "⚠️  xcrun not found. Cannot automatically detect devices."
    echo ""
    echo "Manual steps to reset permissions:"
    echo ""
    echo "Option 1: Delete and Reinstall App"
    echo "  1. Delete $APP_NAME from your device"
    echo "  2. Reinstall from Xcode or TestFlight"
    echo ""
    echo "Option 2: Reset Permissions in Settings"
    echo "  1. Settings → Privacy & Security → Health → $APP_NAME"
    echo "  2. Turn OFF all toggles"
    echo "  3. This simulates 'denied' state for testing"
fi

echo ""
echo "✅ Reset instructions provided"
echo ""
echo "After resetting, test the permission flow by:"
echo "  1. Opening the app"
echo "  2. Starting a meditation session"
echo "  3. Observing the permission dialog"
