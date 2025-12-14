# Fix: Different Container UUIDs Between Watch and iPhone

## Problem

Watch and iPhone are showing different container UUIDs, meaning they're not sharing the same App Group container.

**Watch UUID:** `57EFCE7B-1E38-41C7-A393-CAD1B689E310`
**iPhone UUID:** `9E9FAC76-9A13-463C-99B5-0B72A6D9AA4E`

## Solution Steps

### Step 1: Verify Xcode Signing Configuration

1. **Open Xcode**
2. **Select your project** in the navigator
3. **Select "Plena" target** (iPhone app)
4. **Go to "Signing & Capabilities" tab**
5. **Check:**

   - ✅ "Automatically manage signing" should be **checked**
   - ✅ "App Groups" capability should be visible
   - ✅ `group.com.plena.meditation.coredata` should be **checked**

6. **Select "Plena Watch App" target**
7. **Go to "Signing & Capabilities" tab**
8. **Check:**
   - ✅ "Automatically manage signing" should be **checked**
   - ✅ "App Groups" capability should be visible
   - ✅ `group.com.plena.meditation.coredata` should be **checked**

### Step 2: Force Xcode to Regenerate Profiles

1. **In Xcode, go to:** Xcode → Preferences → Accounts
2. **Select your Apple ID**
3. **Select your team** (Kenneth Nygren - C8SXTF2Y53)
4. **Click "Download Manual Profiles"** button
5. **Wait for it to complete**

### Step 3: Clean Everything

1. **In Xcode:**

   - Product → Clean Build Folder (⌘ShiftK)

2. **Delete DerivedData:**

   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

3. **Delete apps from devices:**
   - Delete Plena from iPhone (long press → Remove App)
   - Delete Plena from Watch (long press → Remove App)

### Step 4: Rebuild with Fresh Profiles

1. **Build iPhone app:**

   - Select "Plena" scheme
   - Select iPhone as destination
   - Build and Run (⌘R)
   - **Check console** - note the container UUID

2. **Build Watch app:**
   - Select "Plena Watch App" scheme
   - Select Watch as destination
   - Build and Run (⌘R)
   - **Check console** - note the container UUID

### Step 5: Verify UUIDs Match

Both apps should now show the **same container UUID**.

## If UUIDs Still Don't Match

### Option A: Manual Provisioning Profile Update

If automatic signing isn't working:

1. **Go to Developer Portal** → **Profiles**
2. **Search for "plena"** to find your profiles
3. **Edit each profile:**

   - Click on profile name
   - Click "Edit"
   - Scroll to "App Groups" section
   - Ensure `group.com.plena.meditation.coredata` is checked
   - Click "Generate" or "Save"
   - Click "Download"

4. **Install profiles in Xcode:**
   - Xcode → Preferences → Accounts
   - Select your account
   - Click "Download Manual Profiles"

### Option B: Check Team ID Consistency

Make sure both apps are using the same Team ID:

1. **In Xcode, check both targets:**
   - Plena target → Signing & Capabilities → Team
   - Plena Watch App target → Signing & Capabilities → Team
   - Both should show: **Kenneth Nygren (C8SXTF2Y53)**

### Option C: Verify App Group in Developer Portal

1. **Go to Developer Portal** → **Identifiers** → **App Groups**
2. **Verify** `group.com.plena.meditation.coredata` exists
3. **Go to** → **Identifiers** → **App IDs**
4. **Check both App IDs:**
   - `com.plena.meditation.app` → App Groups enabled → `group.com.plena.meditation.coredata` checked
   - `com.plena.meditation.app.watchkitapp` → App Groups enabled → `group.com.plena.meditation.coredata` checked

## Expected Result

After fixing, both apps should show:

```
✅ Using App Group shared container: /private/var/mobile/Containers/Shared/AppGroup/[SAME_UUID]/PlenaDataModel.sqlite
   Container UUID: [SAME_UUID]
```

The UUID should be **identical** for both Watch and iPhone.

## Testing

Once UUIDs match:

1. Start a session on Watch
2. Complete the session
3. Open iPhone Dashboard
4. Session should appear automatically
