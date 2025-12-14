# How to Find Your Plena Provisioning Profiles

## Problem

You're seeing profiles for other apps (like `com.knportal.expoonreplit`), but you need to find profiles for your Plena app.

## Solution: Search for Plena Profiles

### Step 1: Use the Search Box

In the Profiles list screen:

1. **Find the search box** (magnifying glass icon, top right)
2. **Type**: `plena` or `com.plena.meditation`
3. **Press Enter** or click search

This will filter the list to show only profiles containing "plena" or your bundle identifier.

### Step 2: Filter by Platform

If you still see many results:

1. **Click the "All Platforms" dropdown** (top right)
2. **Select**: `iOS` (since Plena is an iOS app)
3. This will show only iOS profiles

### Step 3: Look for These Profile Names

Your Plena profiles might be named:

- `Plena Development`
- `Plena Distribution`
- `com.plena.meditation.app Development`
- `com.plena.meditation.app Distribution`
- Or just contain "plena" in the name

### Step 4: Check the App ID Column

If the table shows an App ID column:

- Look for profiles with App ID: `com.plena.meditation.app`
- Or App ID containing: `plena`

## If You Don't See Any Plena Profiles

This means you need to **create** provisioning profiles for your Plena app:

### Create New Provisioning Profile

1. **Click the "+" button** (blue plus icon, top left of Profiles list)
2. **Select Profile Type**:
   - For development: Choose **"iOS App Development"**
   - For App Store/TestFlight: Choose **"App Store"** or **"Ad Hoc"**
3. **Select App ID**:
   - Choose: `com.plena.meditation.app`
4. **Select Certificates**:
   - Choose your development/distribution certificate
5. **Select Devices** (for Development/Ad Hoc):
   - Choose your iPhone and Watch devices
6. **Name the Profile**:
   - Example: `Plena Development` or `Plena App Store`
7. **Generate** and **Download**

### Create Watch App Profile

You'll also need a profile for the Watch app:

1. **Click "+" again**
2. **Select**: `watchOS App Development` or `watchOS App Store`
3. **Select App ID**: `com.plena.meditation.app.watchkitapp`
4. **Select Certificate**: Same certificate
5. **Select Devices**: Same devices
6. **Name**: `Plena Watch Development` or `Plena Watch App Store`
7. **Generate** and **Download**

## After Finding/Creating Profiles

Once you have the correct profiles:

1. **Click on the profile name** to open it
2. **Click "Edit"** button (top right)
3. **Scroll down** to find **"App Groups"** section
4. **Check the box** next to: `group.com.plena.meditation.coredata`
5. **Click "Generate"** or **"Save"**
6. **Click "Download"** to save the updated profile

## Quick Checklist

- [ ] Found profiles for `com.plena.meditation.app`
- [ ] Found profiles for `com.plena.meditation.app.watchkitapp` (if separate)
- [ ] Edited each profile to include App Group
- [ ] Downloaded updated profiles
- [ ] Xcode will automatically use updated profiles (or manually install them)

## Note

If you're using **Automatic Signing** in Xcode:

- Xcode will automatically create/update profiles
- You may not need to manually edit profiles
- Just make sure App Groups are enabled in App IDs (Step 2 of the main guide)

If you're using **Manual Signing**:

- You must manually update and download profiles
- Then install them in Xcode: Xcode → Preferences → Accounts → Download Manual Profiles
