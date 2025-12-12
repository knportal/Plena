# Cleanup Guide for Watch App Installation Issues

## Step 1: Clean Xcode Build Data

1. **Close Xcode completely**

2. **Clean DerivedData:**

   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

3. **Clean Module Cache:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/*
   ```

## Step 2: Remove Old App from Watch

**On your Apple Watch:**

1. Press the Digital Crown to see all apps
2. Find any old "Plena" app
3. Long press the app icon
4. Tap the "X" to delete it

**OR via iPhone Watch App:**

1. Open Watch app on iPhone
2. Go to "My Watch" tab
3. Scroll down to find "Plena" (if it exists)
4. Toggle it OFF or tap it and select "Remove App"

## Step 3: Remove Old App from iPhone

**On your iPhone:**

1. Find any old "Plena" app
2. Long press the app icon
3. Tap "Remove App" → "Delete App"

## Step 4: Clean Xcode Project

1. **Delete user-specific Xcode files:**

   ```bash
   cd /Users/kennethnygren/Cursor/Plena
   rm -rf Plena.xcodeproj/xcuserdata
   rm -rf Plena.xcodeproj/project.xcworkspace/xcuserdata
   ```

2. **Clean build folder in Xcode:**
   - Product → Clean Build Folder (Shift + Cmd + K)

## Step 5: Verify Bundle Identifiers

Current bundle identifiers:

- iOS App: `com.plena.app`
- Watch App: `com.plena.app.watchkitapp`

If you had a different bundle ID before, make sure these are unique.

## Step 6: Rebuild and Install

1. **Open Xcode**
2. **Select "Plena" scheme (iPhone app)**
3. **Select your iPhone as destination**
4. **Build and Run (Cmd + R)**
5. **Check iPhone Watch app** - Plena should appear
6. **Install on watch** via iPhone Watch app

## Step 7: If Still Not Working

Try changing bundle identifiers to something unique:

- iOS: `com.yourname.plena.app`
- Watch: `com.yourname.plena.app.watchkitapp`

Then rebuild from scratch.

