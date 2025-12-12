# How to Register Apple Watch Device on developer.apple.com

## Method 1: Automatic Registration via Xcode (Easier - Try This First)

Xcode can automatically register your watch when you build for it:

1. **In Xcode:**
   - Select **"Plena Watch App"** scheme
   - Try to select your watch from device dropdown (even if it shows as unsupported)
   - Product → Build (Cmd + B)
   - Xcode will prompt you to register the device - click **"Register"**

2. **Or via Devices Window:**
   - Window → Devices and Simulators
   - Select your **Apple Watch**
   - If you see a message about registering, click **"Use for Development"**
   - Xcode will automatically register it

## Method 2: Manual Registration on developer.apple.com

If automatic registration doesn't work:

### Step 1: Get Your Watch UDID

**Option A: From Xcode:**
1. Window → Devices and Simulators
2. Select "Kenneth's Apple Watch"
3. Copy the **Identifier**: `00008310-001728440208A01E`

**Option B: From iPhone:**
1. On iPhone, open **Settings → General → About**
2. Scroll to find your watch name
3. Tap on it to see the watch details including UDID

### Step 2: Register on developer.apple.com

1. **Go to:** https://developer.apple.com/account
2. **Sign in** with your Apple ID
3. **Navigate to:**
   - Click **"Certificates, Identifiers & Profiles"** (left sidebar)
   - Click **"Devices"** (left sidebar)
   - Click the **"+"** button (top right)

4. **Add Device:**
   - **Name:** Enter a name (e.g., "Kenneth's Apple Watch")
   - **UDID:** Paste your watch UDID: `00008310-001728440208A01E`
   - **Platform:** Select **"watchOS"**
   - Click **"Continue"**
   - Review and click **"Register"**

### Step 3: Update Provisioning Profile

After registering the device:

1. **In Xcode:**
   - Select **"Plena Watch App"** target
   - Go to **"Signing & Capabilities"** tab
   - Uncheck **"Automatically manage signing"**
   - Check it again (this forces Xcode to regenerate the profile)
   - Or click **"Download Manual Profiles"** if available

2. **Or on developer.apple.com:**
   - Go to **"Profiles"** section
   - Find your development/distribution profile
   - Click **"Edit"**
   - Make sure your watch device is selected
   - Click **"Generate"** to create a new profile
   - Download and install it

## Method 3: Quick Fix - Let Xcode Auto-Register

The easiest way is to let Xcode handle it:

1. **In Xcode:**
   - Select **"Plena Watch App"** scheme
   - Product → Destination → **"Any watchOS Device"**
   - Product → Build (Cmd + B)
   - If prompted, allow Xcode to register devices

2. **Then try building for your specific watch:**
   - Try selecting your watch from the device list
   - Build again - it should work now

## Troubleshooting

If registration fails:
- Make sure your Apple ID has an active Apple Developer account (free or paid)
- Verify your watch is paired with your iPhone
- Make sure both devices are on the same Apple ID
- Try disconnecting and reconnecting the watch


