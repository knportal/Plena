# Test Plan: Simplified Mindfulness Sensor Architecture

## Overview

This test plan validates the simplified sensor architecture where:
- **iPhone**: Shows only timer during session (no live sensor cards)
- **Watch**: Displays all sensor data during session
- **Post-Session**: Complete data sync from Watch to iPhone for summary

## Test Environment Setup

### Prerequisites
- iPhone with iOS 16+ paired with Apple Watch
- Apple Watch Series 4+ (for HRV) or Series 6+ (for Respiratory Rate)
- HealthKit permissions granted for Heart Rate, HRV (SDNN), and Respiratory Rate
- Watch app installed and paired
- Both devices charged and connected

### Test Data
- Start with clean app state (force quit both apps)
- Ensure no existing sessions in storage

---

## Test Cases

### TC1: Session Start Flow

**Objective**: Verify iPhone can start session and request Watch to start

**Steps**:
1. Open Plena app on iPhone
2. Tap "Start Session"
3. Observe countdown (3, 2, 1)
4. After countdown, verify:
   - iPhone shows timer (00:00)
   - iPhone shows "Session in progress"
   - iPhone shows "Watch connected" if watch is paired
   - Watch app shows sensor data (HR, HRV, RR if enabled)

**Expected Results**:
- ✅ Countdown displays correctly
- ✅ iPhone transitions to timer view (no sensor cards)
- ✅ Watch receives start request and begins session
- ✅ Watch displays sensor data
- ✅ Timer increments every second on iPhone

**Failure Criteria**:
- ❌ iPhone shows sensor cards during session
- ❌ Watch doesn't start session
- ❌ Timer doesn't update
- ❌ Watch doesn't display sensor data

---

### TC2: Timer Display During Session

**Objective**: Verify timer updates correctly on iPhone

**Steps**:
1. Start session (follow TC1)
2. Let session run for 2 minutes
3. Observe timer display

**Expected Results**:
- ✅ Timer format: `MM:SS` (e.g., "02:00")
- ✅ Timer updates every second
- ✅ Timer is accurate (compare with stopwatch)
- ✅ No sensor cards visible on iPhone
- ✅ Watch continues showing sensor data

**Failure Criteria**:
- ❌ Timer doesn't update
- ❌ Timer format incorrect
- ❌ Timer is inaccurate
- ❌ Sensor cards appear on iPhone

---

### TC3: Watch Sensor Data Collection

**Objective**: Verify Watch collects all enabled sensor data

**Steps**:
1. Start session with all sensors enabled
2. Let session run for 5 minutes
3. Observe Watch display:
   - Heart Rate updates
   - HRV appears (may take 1-2 minutes)
   - Respiratory Rate appears (may take 1-2 minutes)

**Expected Results**:
- ✅ Heart Rate updates every 1-2 seconds on Watch
- ✅ HRV appears within 2 minutes (if Series 4+)
- ✅ Respiratory Rate appears within 2 minutes (if Series 6+)
- ✅ All sensor values are reasonable (HR: 50-120 BPM, HRV: 20-100ms, RR: 8-20/min)
- ✅ Watch display is responsive

**Failure Criteria**:
- ❌ Heart Rate never appears
- ❌ HRV never appears after 5 minutes (if enabled)
- ❌ Respiratory Rate never appears after 5 minutes (if enabled)
- ❌ Sensor values are clearly incorrect

---

### TC4: Session End and Post-Session Sync

**Objective**: Verify complete data transfer from Watch to iPhone

**Steps**:
1. Start session and let run for 3-5 minutes
2. Stop session on Watch (or iPhone)
3. Observe:
   - Watch sends session package
   - iPhone receives package
   - iPhone shows session summary

**Expected Results**:
- ✅ Session ends cleanly on both devices
- ✅ Watch sends SessionSyncPackage via WatchConnectivity
- ✅ iPhone receives package within 5 seconds
- ✅ Session summary appears on iPhone with:
  - Average Heart Rate
  - HRV change (start → end)
  - Respiratory Rate average
  - Session duration
- ✅ All collected samples are included in summary

**Failure Criteria**:
- ❌ Session package not received
- ❌ Summary missing data
- ❌ Summary shows incorrect values
- ❌ Package transfer fails silently

---

### TC5: Watch Disconnected During Session

**Objective**: Verify graceful handling when Watch disconnects

**Steps**:
1. Start session
2. Disconnect Watch (turn off Bluetooth or move out of range)
3. Let session continue for 1 minute
4. Reconnect Watch
5. Stop session

**Expected Results**:
- ✅ iPhone timer continues running
- ✅ iPhone shows "Watch disconnected" or similar status
- ✅ Watch continues collecting data locally
- ✅ When reconnected, post-session sync still works
- ✅ Complete data is transferred after reconnection

**Failure Criteria**:
- ❌ iPhone app crashes
- ❌ Timer stops
- ❌ Data is lost
- ❌ Post-session sync fails

---

### TC6: iPhone App Backgrounded

**Objective**: Verify session continues when iPhone app is backgrounded

**Steps**:
1. Start session
2. Background iPhone app (home button/swipe up)
3. Let session run for 2 minutes
4. Foreground iPhone app
5. Stop session

**Expected Results**:
- ✅ Session continues on Watch
- ✅ Timer resumes when app is foregrounded
- ✅ Post-session package is received even if app was backgrounded
- ✅ Summary displays correctly

**Failure Criteria**:
- ❌ Session stops when app is backgrounded
- ❌ Timer doesn't resume
- ❌ Post-session package is lost

---

### TC7: Watch App Backgrounded

**Objective**: Verify session continues when Watch app is backgrounded

**Steps**:
1. Start session
2. Press Digital Crown on Watch (background app)
3. Let session run for 2 minutes
4. Reopen Watch app
5. Stop session

**Expected Results**:
- ✅ Session continues in background
- ✅ Sensors continue collecting data
- ✅ Watch app shows correct state when reopened
- ✅ Post-session sync works correctly

**Failure Criteria**:
- ❌ Session stops when app is backgrounded
- ❌ Data collection stops
- ❌ Post-session sync fails

---

### TC8: Multiple Sessions in Sequence

**Objective**: Verify multiple sessions work correctly

**Steps**:
1. Start and complete Session 1 (3 minutes)
2. Wait 30 seconds
3. Start and complete Session 2 (3 minutes)
4. Verify both sessions are saved

**Expected Results**:
- ✅ First session summary appears and can be dismissed
- ✅ Second session starts correctly
- ✅ Both sessions are saved to storage
- ✅ Both sessions have complete data
- ✅ No data mixing between sessions

**Failure Criteria**:
- ❌ Second session doesn't start
- ❌ Data from Session 1 appears in Session 2
- ❌ Sessions are not saved
- ❌ App crashes

---

### TC9: Session Interrupted (Force Quit)

**Objective**: Verify data recovery when app is force quit

**Steps**:
1. Start session
2. Let run for 2 minutes
3. Force quit iPhone app
4. Reopen iPhone app
5. Verify session state

**Expected Results**:
- ✅ App doesn't crash on reopen
- ✅ Session state is handled gracefully
- ✅ If Watch session still active, post-session sync works when Watch session ends
- ✅ No orphaned sessions

**Failure Criteria**:
- ❌ App crashes on reopen
- ❌ Session state is corrupted
- ❌ Data is lost

---

### TC10: Long Session (30+ minutes)

**Objective**: Verify system handles long sessions correctly

**Steps**:
1. Start session
2. Let run for 30 minutes
3. Stop session
4. Verify all data is collected and synced

**Expected Results**:
- ✅ Timer continues accurately for 30 minutes
- ✅ Watch continues collecting data
- ✅ No memory issues
- ✅ Post-session package includes all data
- ✅ Summary calculates correctly

**Failure Criteria**:
- ❌ Timer stops or becomes inaccurate
- ❌ Memory issues (app crashes)
- ❌ Data is missing from package
- ❌ Summary calculation fails

---

### TC11: Sensor Permissions Denied

**Objective**: Verify graceful handling when permissions are denied

**Steps**:
1. Deny HealthKit permissions for Heart Rate
2. Start session
3. Observe behavior

**Expected Results**:
- ✅ Error message appears on iPhone
- ✅ Session doesn't start if required permissions denied
- ✅ Clear instructions to enable permissions
- ✅ No crashes

**Failure Criteria**:
- ❌ App crashes
- ❌ Session starts without permissions
- ❌ Unclear error messages

---

### TC12: Watch Not Paired/Installed

**Objective**: Verify behavior when Watch is not available

**Steps**:
1. Unpair Watch or uninstall Watch app
2. Start session on iPhone
3. Observe behavior

**Expected Results**:
- ✅ Clear message that Watch is required
- ✅ Session doesn't start
- ✅ No crashes
- ✅ Helpful instructions

**Failure Criteria**:
- ❌ App crashes
- ❌ Session starts without Watch
- ❌ Unclear error messages

---

## Performance Benchmarks

### Timer Accuracy
- **Target**: ±1 second over 10 minutes
- **Measurement**: Compare iPhone timer with external stopwatch

### Post-Session Sync Speed
- **Target**: Package received within 5 seconds of session end
- **Measurement**: Time from session end to summary display

### Memory Usage
- **Target**: No memory growth during 30-minute session
- **Measurement**: Monitor memory usage in Instruments

### Battery Impact
- **Target**: Minimal battery drain during session
- **Measurement**: Monitor battery percentage before/after 30-minute session

---

## Regression Tests

### R1: Existing Features Still Work
- [ ] Session summary displays correctly
- [ ] Data visualization shows historical sessions
- [ ] Settings can enable/disable sensors
- [ ] HealthKit mindful session is saved

### R2: Watch Display Unchanged
- [ ] Watch still shows sensor cards during session
- [ ] Watch summary view works correctly
- [ ] Watch navigation is unchanged

---

## Test Execution Checklist

### Pre-Test
- [ ] Both devices charged (>50%)
- [ ] HealthKit permissions granted
- [ ] Watch paired and connected
- [ ] Apps updated to latest version
- [ ] Test environment clean (no existing sessions)

### During Test
- [ ] Execute all test cases in sequence
- [ ] Document any failures with:
  - Steps to reproduce
  - Expected vs actual behavior
  - Screenshots/logs
  - Device/OS versions

### Post-Test
- [ ] Review all test results
- [ ] Document performance metrics
- [ ] Create bug reports for failures
- [ ] Verify fixes for any issues found

---

## Success Criteria

**All tests must pass for release**:
- ✅ TC1-TC12: All functional tests pass
- ✅ Performance benchmarks met
- ✅ Regression tests pass
- ✅ No crashes or data loss
- ✅ Post-session sync reliability >95%

---

## Known Limitations

1. **HRV/RR Timing**: HRV and Respiratory Rate may take 1-2 minutes to appear (normal Apple Watch behavior)
2. **Watch Disconnection**: If Watch disconnects for >5 minutes, some data may be lost
3. **Background Limits**: iOS may limit background execution after extended periods

---

## Test Tools

- **Xcode Instruments**: Memory profiling
- **Console.app**: Log monitoring
- **WatchConnectivity Debugging**: Enable in Xcode scheme
- **HealthKit Debugging**: Use Health app to verify data

---

## Test Sign-Off

**Tester**: _________________
**Date**: _________________
**Version**: _________________
**Result**: ☐ Pass  ☐ Fail  ☐ Partial

**Notes**:
_____________________________________________________________
_____________________________________________________________
_____________________________________________________________

