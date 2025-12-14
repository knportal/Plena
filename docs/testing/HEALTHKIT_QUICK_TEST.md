# HealthKit Permissions - Quick Test Reference

Quick steps to test HealthKit permissions flow.

## 🔄 Reset Permissions

**Method 1: Delete & Reinstall (Best for first-time flow)**

```bash
# On device: Delete app, then reinstall from Xcode
# OR use the helper script:
./scripts/reset_healthkit_permissions.sh
```

**Method 2: Settings Reset (Faster)**

1. Settings → Privacy & Security → Health → Plena
2. Turn OFF all permissions
3. Return to app

## ✅ Test Permission Request

1. **Delete/reinstall app OR turn off all permissions in Settings**

2. **Start a meditation session:**

   - App will request permissions automatically
   - iOS shows permission dialog
   - Grant/deny permissions

3. **Check console logs:**
   ```
   📋 Requesting HealthKit authorization...
   ✅ HealthKit authorization request completed
   📊 Authorization Statuses:
      Heart Rate: 2 (Sharing Authorized)
      HRV: 2 (Sharing Authorized)
      ...
   ```

## 🧪 Test Scenarios

### Scenario A: First Time - Grant All

- Start session → Grant all permissions → ✅ Session starts

### Scenario B: Deny Required Permissions

- Start session → Deny Heart Rate/HRV/Respiratory Rate → ❌ Error message shown

### Scenario C: Deny Optional Permissions

- Start session → Deny VO2 Max/Temperature → ✅ Session starts (required permissions OK)

### Scenario D: Manual Re-request

- Settings → Privacy → "Re-request Authorization" → Permission dialog appears

### Scenario E: Check Status

- Settings → Privacy → "Refresh Status" → Check console for current permissions

## 🐛 Debug Checklist

- [ ] Info.plist has `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription`
- [ ] HealthKit capability enabled in Xcode project
- [ ] Testing on real device (or iOS 15+ simulator for dialogs)
- [ ] Console shows permission status logs
- [ ] Error messages are user-friendly when permissions denied

## 📍 Where Permissions Are Requested

1. **Automatic:** `MeditationSessionViewModel.startSession()` (line 120)
2. **Manual:** `SettingsView` → "Re-request Authorization" button (line 139)

## 🔍 Check Current Status

Use Settings → Privacy → "Refresh Status" button, or check console output:

```
🔍 Checking HealthKit authorization status...
📊 Current Authorization Statuses:
   Heart Rate: 2 (Sharing Authorized)
   ...
```

## ⚠️ Common Issues

**Permission dialog not appearing:**

- Permissions already requested → Reset first
- Simulator < iOS 15 → Use real device or newer simulator

**Wrong error message:**

- Check `HealthKitError` cases in `HealthKitService.swift`
- Verify required vs optional permissions logic

**Session starts with denied permissions:**

- Check that `requestAuthorization()` is called before starting queries
- Verify error handling in `MeditationSessionViewModel.startSession()`

---

For detailed testing, see `HEALTHKIT_PERMISSIONS_TESTING.md`
