# Plena Troubleshooting Guide

Common issues and solutions for the Plena meditation tracking app.

---

## Table of Contents

1. [HealthKit & Permissions](#healthkit--permissions)
2. [Sensor Data Issues](#sensor-data-issues)
3. [Apple Watch Issues](#apple-watch-issues)
4. [Data & Sync Issues](#data--sync-issues)
5. [Performance Issues](#performance-issues)
6. [General Issues](#general-issues)
7. [When to Contact Support](#when-to-contact-support)

---

## HealthKit & Permissions

### "HealthKit not authorized" Error

**Symptoms:**

- Error message when trying to start a session
- "Permission denied" alerts
- No sensor data appears

**Solutions:**

1. **Check Current Permissions:**

   - Open **Settings** on iPhone
   - Go to **Privacy & Security** → **Health**
   - Tap **Plena**
   - Ensure all required data types are turned ON (green)

2. **Re-request Permissions:**

   - If permissions are OFF, turn them ON manually
   - Or delete and reinstall the app to trigger permission prompts again

3. **Verify Device:**
   - HealthKit only works on physical devices
   - Simulators cannot access HealthKit
   - Ensure you're running on a real iPhone/Apple Watch

### Permission Denied Messages

**Symptoms:**

- Specific permission errors for individual sensors
- Some sensors work, others don't

**Solutions:**

1. **Check Individual Permissions:**

   - Settings → Privacy & Security → Health → Plena
   - Verify each data type:
     - ✅ Heart Rate (Read)
     - ✅ Heart Rate Variability (Read)
     - ✅ Respiratory Rate (Read)
     - ✅ Body Temperature (Read)
     - ✅ VO₂ Max (Read)
     - ✅ Mindfulness (Write)

2. **Grant Missing Permissions:**

   - Turn ON any data types that are OFF
   - Exit Settings and try starting a session again

3. **Restart the App:**
   - Force quit Plena
   - Reopen and try again

### How to Check/Change Permissions

**On iPhone:**

1. Open **Settings**
2. Navigate to **Privacy & Security**
3. Tap **Health**
4. Find and tap **Plena**
5. Review all data types
6. Toggle ON any that are OFF

**On Apple Watch:**

- Watch app permissions mirror iPhone permissions
- Change permissions on iPhone to affect Watch

### Re-requesting Permissions

If you need to re-request permissions:

1. **Delete the app** (tap and hold app icon, tap Remove → Delete App)
2. **Restart your iPhone**
3. **Reinstall Plena** from App Store
4. **Grant permissions** when prompted

**Note:** This will delete local app data. Your HealthKit data remains safe.

---

## Sensor Data Issues

### No Heart Rate Data Appearing

**Symptoms:**

- Heart rate card shows "--" or is missing
- No BPM values during session

**Solutions:**

1. **Check Apple Watch Connection:**

   - Ensure Apple Watch is paired and connected
   - Check Watch battery level
   - Verify Watch is on your wrist and snug

2. **Check HealthKit Data:**

   - Open **Health** app on iPhone
   - Go to **Browse** → **Heart** → **Heart Rate**
   - Verify there's recent heart rate data
   - If no data, try a workout or manual heart rate reading

3. **Restart Devices:**

   - Restart both iPhone and Apple Watch
   - Try starting a session again

4. **Check Watch Fit:**
   - Ensure Watch is snug but comfortable
   - Clean the sensor on the back of Watch
   - Ensure Watch isn't too loose

### Missing HRV Readings

**Symptoms:**

- HRV shows "--" or "N/A"
- No HRV zone classification
- HRV card doesn't appear

**Solutions:**

1. **Check Watch Model:**

   - HRV requires Apple Watch Series 4 or later
   - Series 1-3 do not support HRV
   - See [Apple Watch Compatibility Guide](APPLE_WATCH_COMPATIBILITY.md) for details

2. **Session Duration:**

   - HRV requires sufficient data
   - Minimum 3 HRV samples needed
   - Try meditating for 10+ minutes

3. **Check HealthKit Data:**

   - Open **Health** app
   - Go to **Heart** → **Heart Rate Variability**
   - Verify HRV data exists
   - HRV is measured less frequently than heart rate

4. **Positioning:**
   - Keep your arm relatively still
   - HRV readings need stable conditions
   - Avoid excessive movement

### Respiratory Rate Not Showing

**Symptoms:**

- Respiratory rate card missing or blank
- No breathing rate data

**Solutions:**

1. **Check Watch Model:**

   - Respiratory rate requires Apple Watch Series 6 or later
   - Series 1-5 do not support respiratory rate
   - See [Apple Watch Compatibility Guide](APPLE_WATCH_COMPATIBILITY.md) for details

2. **Check HealthKit:**

   - Open **Health** app
   - Go to **Respiratory** → **Respiratory Rate**
   - Verify data exists

3. **Wait for Reading:**
   - Respiratory rate may take longer to appear
   - Continue meditating and allow time for measurement
   - Ensure Watch is detecting movement (breathing)

### "Sensor Unavailable" Messages

**Symptoms:**

- Messages like "Heart rate sensor unavailable"
- Sensors grayed out or disabled

**Solutions:**

1. **Check Watch Connection:**

   - Ensure Watch is connected to iPhone
   - Verify Bluetooth is enabled
   - Check Watch battery (low battery affects sensors)

2. **Restart Watch:**

   - Hold side button on Watch
   - Slide "Power Off"
   - Wait 30 seconds, then power on
   - Try session again

3. **Check WatchOS Version:**
   - Ensure Watch is running watchOS 10.0 or later
   - Update if needed: Watch app → General → Software Update

### Sensor Accuracy Problems

**Symptoms:**

- Readings seem incorrect
- Values fluctuating wildly
- Unrealistic numbers

**Solutions:**

1. **Proper Watch Fit:**

   - Watch should be snug but not tight
   - Should be able to move one finger between band and wrist
   - Ensure sensor contacts your skin

2. **Clean Sensors:**

   - Clean back of Watch with soft, slightly damp cloth
   - Remove any dirt, sweat, or lotion
   - Dry thoroughly before use

3. **Minimize Movement:**

   - Stay relatively still during readings
   - Excessive movement affects accuracy
   - Rest your arm if possible

4. **Skin Conditions:**
   - Tattoos, scars, or very dark skin may affect sensors
   - Try moving Watch to different position on wrist
   - Some users have better results on inner wrist

---

## Apple Watch Issues

### Watch App Not Syncing

**Symptoms:**

- Sessions started on Watch don't appear on iPhone
- Data from Watch sessions missing
- Watch and iPhone show different data

**Solutions:**

1. **Check CloudKit/ iCloud:**

   - Ensure iCloud is enabled on both devices
   - Settings → [Your Name] → iCloud
   - Verify iCloud Drive is ON

2. **Check Watch Connection:**

   - Ensure Watch is paired and connected
   - Look for Watch icon in iPhone Control Center
   - Check Bluetooth is enabled

3. **Restart Both Devices:**

   - Restart iPhone
   - Restart Apple Watch
   - Wait for reconnection
   - Try syncing again

4. **Reinstall Watch App:**
   - On iPhone, open **Watch** app
   - Find Plena under "Installed on Apple Watch"
   - Toggle OFF, wait 10 seconds, toggle ON
   - Wait for reinstallation

### Can't Start Session from Watch

**Symptoms:**

- Watch app crashes when starting session
- "Unable to start session" error
- App freezes on Watch

**Solutions:**

1. **Check Permissions:**

   - Ensure HealthKit permissions granted on iPhone
   - Watch inherits iPhone permissions

2. **Restart Watch:**

   - Hold side button
   - Slide "Power Off"
   - Wait 30 seconds, power on

3. **Reinstall Watch App:**

   - Delete Watch app from Watch
   - Reinstall from iPhone Watch app
   - Try again

4. **Check WatchOS Version:**
   - Update to latest watchOS 10.0+
   - Watch app → General → Software Update

### Watch App Crashes

**Symptoms:**

- App closes unexpectedly
- Black screen or frozen interface
- Watch returns to home screen

**Solutions:**

1. **Force Quit and Restart:**

   - Press Digital Crown to go to home screen
   - Swipe up to see open apps
   - Swipe up on Plena to close it
   - Reopen Plena app

2. **Restart Watch:**

   - Hold side button until "Power Off" appears
   - Slide to power off
   - Wait 30 seconds
   - Press side button to power on

3. **Reinstall App:**

   - Delete Watch app
   - Reinstall from iPhone
   - Test again

4. **Check Storage:**
   - Watch app → General → About
   - Check available storage
   - Free up space if needed

### Connection Between iPhone/Watch Lost

**Symptoms:**

- "iPhone not connected" message
- Watch app shows disconnected state
- Data not syncing

**Solutions:**

1. **Check Bluetooth:**

   - On iPhone: Settings → Bluetooth
   - Ensure Bluetooth is ON
   - Check Watch appears in "My Devices"

2. **Check Distance:**

   - Keep iPhone and Watch within Bluetooth range (~30 feet)
   - Bring devices closer together

3. **Restart Both Devices:**

   - Restart iPhone
   - Restart Apple Watch
   - Wait for reconnection

4. **Unpair and Re-pair (Last Resort):**
   - Watch app → My Watch → [Your Watch] → Unpair
   - Follow on-screen instructions
   - Re-pair Watch
   - **Warning:** This erases Watch content

### Watch Permissions Not Working

**Symptoms:**

- Watch asks for permissions repeatedly
- Permissions seem to reset
- HealthKit errors on Watch

**Solutions:**

1. **Sync Permissions from iPhone:**

   - Grant all permissions on iPhone first
   - Watch should inherit these permissions
   - Check: Watch app → Privacy & Security → Health

2. **Restart Both Devices:**

   - Restart iPhone
   - Restart Watch
   - Permissions should sync

3. **Reinstall Watch App:**
   - Delete Plena from Watch
   - Reinstall from iPhone
   - Permissions will be inherited

---

## Data & Sync Issues

### Sessions Not Saving

**Symptoms:**

- Session summary appears but disappears
- Sessions don't appear in Dashboard
- "Session not saved" errors

**Solutions:**

1. **Check Storage Space:**

   - Settings → General → iPhone Storage
   - Ensure sufficient free space (100MB+ recommended)
   - Free up space if needed

2. **Restart App:**

   - Force quit Plena
   - Reopen app
   - Check Dashboard for saved sessions

3. **Check CoreData:**
   - App uses CoreData for local storage
   - Reinstall app if persistent issues
   - **Note:** This will delete local data (HealthKit data safe)

### Missing Historical Data

**Symptoms:**

- Previous sessions not appearing
- Dashboard shows no data
- Data visualization empty

**Solutions:**

1. **Check Time Range:**

   - Dashboard and Data tabs have time range selectors
   - Ensure correct range selected (Day/Week/Month/Year)
   - Try different time ranges

2. **Verify Data Exists:**

   - Check Health app for meditation data
   - Open Health → Browse → Mindfulness
   - Verify sessions are recorded

3. **Import Historical Data:**
   - Use HealthKit import feature if available
   - Settings → Import Historical Data
   - Follow on-screen instructions

### CloudKit Sync Problems

**Symptoms:**

- Data doesn't sync between iPhone and Watch
- "Sync failed" messages
- Different data on each device

**Solutions:**

1. **Check iCloud:**

   - Settings → [Your Name] → iCloud
   - Ensure iCloud Drive is ON
   - Verify signed into same iCloud account on both devices

2. **Check CloudKit Container:**

   - Ensure CloudKit is enabled in app
   - App requires CloudKit for sync
   - Check app settings

3. **Force Sync:**

   - Open app on iPhone
   - Open app on Watch
   - Both devices online
   - Wait a few minutes for sync

4. **Restart Devices:**
   - Restart both iPhone and Watch
   - Reopen apps on both devices
   - Allow time for sync

### Data Import Failures

**Symptoms:**

- Historical import doesn't work
- "Import failed" errors
- No data imported from HealthKit

**Solutions:**

1. **Check HealthKit Data:**

   - Verify data exists in Health app
   - Ensure data is in correct format
   - Check data dates (some apps have date limits)

2. **Check Permissions:**

   - Ensure full HealthKit read permissions
   - Re-request permissions if needed

3. **Try Manual Import:**
   - Some data may need manual import
   - Use test data generator if needed (development only)

---

## Performance Issues

### App Running Slowly

**Symptoms:**

- App is sluggish or laggy
- Slow response to taps
- Charts load slowly

**Solutions:**

1. **Close Other Apps:**

   - Close background apps
   - Free up device memory
   - Restart iPhone

2. **Check Device Storage:**

   - Settings → General → iPhone Storage
   - Free up space if device is full
   - Delete unused apps/files

3. **Update iOS:**

   - Settings → General → Software Update
   - Install latest iOS version
   - App optimized for iOS 17.0+

4. **Restart iPhone:**
   - Power off completely
   - Wait 30 seconds
   - Power on
   - Clear memory cache

### Battery Drain Concerns

**Symptoms:**

- iPhone battery drains quickly
- Watch battery dies faster than normal

**Solutions:**

1. **Sensor Usage:**

   - Continuous sensor monitoring uses battery
   - This is normal during active sessions
   - Close app when not in use

2. **Background App Refresh:**

   - Settings → General → Background App Refresh
   - Can disable for Plena if not needed
   - May affect sync functionality

3. **Check Other Apps:**

   - Other apps may be causing drain
   - Check battery usage: Settings → Battery
   - Identify battery-hungry apps

4. **Optimize Settings:**
   - Reduce screen brightness
   - Enable Low Power Mode if needed
   - Close unnecessary background apps

### Watch Battery Issues

**Symptoms:**

- Watch battery drains during sessions
- Watch dies quickly

**Solutions:**

1. **This is Normal:**

   - Continuous heart rate monitoring uses battery
   - Typical session: 5-10% battery per 20 minutes
   - This is expected behavior

2. **Optimize Watch:**

   - Reduce screen brightness
   - Enable Power Reserve mode if needed
   - Close other Watch apps

3. **Check Watch Battery Health:**
   - Watch app → General → About
   - Check battery condition
   - Replace Watch battery if degraded

---

## General Issues

### App Crashes

**Symptoms:**

- App closes unexpectedly
- Returns to home screen
- Error messages before crash

**Solutions:**

1. **Force Quit and Restart:**

   - Swipe up from bottom (or double-tap home)
   - Swipe up on Plena to close
   - Reopen app

2. **Restart iPhone:**

   - Power off completely
   - Wait 30 seconds
   - Power on

3. **Update App:**

   - Check App Store for updates
   - Install latest version
   - Updates fix known bugs

4. **Reinstall App:**
   - Delete Plena
   - Restart iPhone
   - Reinstall from App Store
   - **Warning:** This deletes local app data

### Can't Start Meditation Session

**Symptoms:**

- "Start Session" button doesn't work
- Button appears disabled
- Nothing happens when tapped

**Solutions:**

1. **Check Permissions:**

   - Verify HealthKit permissions granted
   - Settings → Privacy & Security → Health → Plena

2. **Check Device:**

   - Ensure using physical device (not simulator)
   - HealthKit requires real hardware

3. **Restart App:**

   - Force quit Plena
   - Reopen app
   - Try again

4. **Check Watch Connection (if using Watch):**
   - Ensure Watch is connected
   - Verify Watch app is installed

### Countdown Not Working

**Symptoms:**

- 3-2-1 countdown doesn't appear
- Countdown freezes
- Session starts immediately without countdown

**Solutions:**

1. **Wait for Countdown:**

   - Countdown should appear automatically
   - Takes 3 seconds total
   - Ensure screen is visible

2. **Check App State:**

   - Ensure app is in foreground
   - Don't switch apps during countdown
   - Keep screen unlocked

3. **Restart Session:**
   - Stop current session (if any)
   - Tap "Start Session" again
   - Countdown should begin

### Session Summary Not Appearing

**Symptoms:**

- No summary after stopping session
- Summary screen is blank
- Can't review session data

**Solutions:**

1. **Wait a Moment:**

   - Summary takes a few seconds to generate
   - Allow time for calculations
   - Don't close app immediately

2. **Check Session Duration:**

   - Very short sessions (< 30 seconds) may not generate summary
   - Try longer session (1+ minute minimum)

3. **Restart App:**

   - Force quit Plena
   - Reopen app
   - Summary may appear in Dashboard

4. **Check Dashboard:**
   - Summary data should appear in Dashboard
   - Go to Dashboard tab
   - Check recent sessions

---

## When to Contact Support

### Issues Not Covered

If you've tried the solutions above and your issue persists:

1. **Document the Issue:**

   - Note exact error messages
   - Record steps to reproduce
   - Note iOS/WatchOS versions
   - Take screenshots if possible

2. **Check for Updates:**

   - Ensure app is latest version
   - Update iOS/WatchOS if available
   - Try again after updates

3. **Contact Support:**
   - See App Store listing for support email/URL
   - Include device information
   - Describe issue in detail

### How to Report Bugs

When reporting bugs, include:

- **Device Information:**

  - iPhone model and iOS version
  - Apple Watch model and watchOS version (if applicable)
  - App version (Settings → Plena → Version)

- **Issue Description:**

  - What you were doing
  - What happened
  - What you expected
  - Steps to reproduce

- **Error Messages:**

  - Exact error text
  - Screenshots if available
  - When error occurred

- **Troubleshooting Attempted:**
  - What you've already tried
  - Which solutions didn't work

### Support Contact Information

- **Support Email:** hello@plenitudo.ai
- **General Inquiries:** info@plenitudo.ai
- **Privacy Policy:** [Add privacy policy URL]
- **App Store Listing:** See App Store for contact options

---

## Quick Troubleshooting Checklist

Before contacting support, try these in order:

- [ ] Restart the app (force quit and reopen)
- [ ] Restart your iPhone
- [ ] Restart your Apple Watch (if applicable)
- [ ] Check HealthKit permissions
- [ ] Verify device compatibility (iOS 17.0+, watchOS 10.0+)
- [ ] Ensure using physical device (not simulator)
- [ ] Check available storage space
- [ ] Update app to latest version
- [ ] Update iOS/WatchOS to latest version
- [ ] Reinstall app (last resort - deletes local data)

---

_For setup help, see [User Guide](USER_GUIDE.md)._
_For app overview, see [App Overview](APP_OVERVIEW.md)._
