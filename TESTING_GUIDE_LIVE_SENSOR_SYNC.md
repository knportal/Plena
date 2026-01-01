# Testing Guide: Live Sensor Sync Implementation

**Date:** 2025-12-28
**Feature:** Real-time sensor data streaming from Watch to iPhone

## Pre-Testing Checklist

- [ ] Both iPhone and Apple Watch are paired and connected
- [ ] Both devices have Bluetooth enabled
- [ ] Watch app is installed on Apple Watch
- [ ] HealthKit permissions are granted on iPhone
- [ ] Both devices are within Bluetooth range (~30 feet)

## Test Scenarios

### Test 1: Watch → iPhone Live Data Stream

**Objective:** Verify that starting a session on the watch streams live data to iPhone in real-time.

**Steps:**

1. Open Plena app on iPhone (keep it open/foreground)
2. Open Plena app on Apple Watch
3. Start a meditation session on the Watch
4. **Expected:** iPhone should show live heart rate, HRV, and respiratory rate updates within 1 second
5. Watch the values update in real-time on iPhone
6. Stop session on Watch
7. **Expected:** Session should sync to iPhone automatically

**Success Criteria:**

- ✅ iPhone receives live updates within 1-2 seconds of watch readings
- ✅ Values match between watch and iPhone
- ✅ No "waiting for data" messages on iPhone
- ✅ Session appears in iPhone after completion

**Console Logs to Check:**

- Look for: `✅ Sent session ... to iPhone via WatchConnectivity`
- Look for: `📊 Heart rate query received X sample(s)` (should be minimal if live data is working)
- Look for: `⚠️ Stopped receiving live data from watch` (should NOT appear during active session)

---

### Test 2: iPhone → Watch Session Start

**Objective:** Verify that starting a session on iPhone triggers the watch to start its session.

**Steps:**

1. Open Plena app on iPhone
2. Ensure watch is reachable (check connection status)
3. Start a meditation session on iPhone
4. **Expected:** Watch should automatically start its session
5. Check watch - should show countdown and then start tracking
6. Stop session on iPhone
7. **Expected:** Watch session should also stop

**Success Criteria:**

- ✅ Watch receives session start request from iPhone
- ✅ Watch starts its own session automatically
- ✅ Both devices track simultaneously
- ✅ Watch shows live sensor data

**Console Logs to Check:**

- Look for: `📱 Received meditation session start request from iPhone`
- Look for: `✅ Watch app requested to start meditation session`
- Look for: `✅ Watch app requested to start workout session`

---

### Test 3: Data Consistency

**Objective:** Verify that both devices show the same sensor values.

**Steps:**

1. Start session on either device
2. Compare heart rate values on both devices
3. Compare HRV values on both devices
4. Compare respiratory rate values on both devices
5. **Expected:** Values should match (within 1-2 seconds)

**Success Criteria:**

- ✅ Heart rate values match between devices
- ✅ HRV values match between devices
- ✅ Respiratory rate values match between devices
- ✅ Timestamps are recent (not stale)

---

### Test 4: Watch Out of Range / Connection Loss

**Objective:** Verify graceful fallback when watch becomes unreachable.

**Steps:**

1. Start session on iPhone (which triggers watch session)
2. Verify live data is streaming to iPhone
3. Move watch out of Bluetooth range (or turn off watch)
4. **Expected:** iPhone should detect loss of live data and fall back to HealthKit queries
5. Wait 5-10 seconds
6. **Expected:** iPhone should continue showing data (from HealthKit)
7. Bring watch back in range
8. **Expected:** Live data should resume automatically

**Success Criteria:**

- ✅ iPhone detects when watch stops sending (within 5 seconds)
- ✅ iPhone falls back to HealthKit queries
- ✅ No crashes or errors
- ✅ Live data resumes when watch reconnects

**Console Logs to Check:**

- Look for: `⚠️ Stopped receiving live data from watch - falling back to iPhone HealthKit`
- Look for: `⚠️ Error sending live sample to iPhone` (when out of range)

---

### Test 5: Long Session (30+ minutes)

**Objective:** Verify stability and performance during extended sessions.

**Steps:**

1. Start session on watch
2. Let it run for 30+ minutes
3. Monitor iPhone for live updates
4. Check memory usage (Xcode Instruments)
5. Check battery impact
6. Stop session

**Success Criteria:**

- ✅ No memory leaks or crashes
- ✅ Live data continues streaming throughout session
- ✅ Battery drain is reasonable
- ✅ Throttling works (1 sample/second per sensor)

**Console Logs to Check:**

- Monitor for memory warnings
- Check sample send frequency (should be ~1/second per sensor)
- Look for any error messages

---

### Test 6: Both Devices Running Sessions Simultaneously

**Objective:** Verify behavior when both devices are tracking independently.

**Steps:**

1. Start session on iPhone (don't let it trigger watch)
2. Start separate session on watch
3. **Expected:** Both should track independently
4. iPhone should receive live data from watch
5. iPhone should also have its own HealthKit data
6. Stop both sessions

**Success Criteria:**

- ✅ Both sessions run independently
- ✅ iPhone receives live data from watch
- ✅ No conflicts or crashes
- ✅ Both sessions save correctly

---

## Debugging Tips

### Enable Verbose Logging

Add to your console filter:

- `WatchConnectivity`
- `live sample`
- `Received meditation session`
- `Stopped receiving live data`

### Common Issues

1. **"Watch not reachable"**

   - Check Bluetooth connection
   - Ensure watch is on wrist (not charging)
   - Restart both devices if needed

2. **"No live data received"**

   - Check watch is actually sending (look for `sendLiveSample` logs)
   - Verify watch session is active
   - Check WatchConnectivity activation state

3. **"Different data on devices"**

   - This should NOT happen with live sync
   - If it does, check if live data is actually being received
   - Verify `isReceivingLiveDataFromWatch` is true

4. **"Session not starting on watch"**
   - Check meditation session request handler is registered
   - Verify WatchConnectivity is activated
   - Check console for error messages

### Performance Monitoring

Use Xcode Instruments to monitor:

- **Memory:** Should be stable, no leaks
- **CPU:** Should be low (< 5% during idle)
- **Network:** WatchConnectivity traffic should be minimal (~1KB/second)
- **Battery:** Should not drain significantly faster

---

## Expected Console Output

### Successful Live Data Stream:

```
✅ WatchConnectivity session activated
📊 Heart rate query received 1 sample(s)
   → HR: 72.0 BPM (age: 0.5s)
✅ Sent session ... to iPhone via WatchConnectivity
```

### Watch Starting from iPhone Request:

```
📱 Received meditation session start request from iPhone
✅ Watch: Workout session started successfully from iPhone request
```

### Fallback to HealthKit:

```
⚠️ Stopped receiving live data from watch - falling back to iPhone HealthKit
📊 Heart rate query received 1 sample(s)
```

---

## Success Metrics

- ✅ **Latency:** < 2 seconds from watch reading to iPhone display
- ✅ **Consistency:** Values match between devices
- ✅ **Reliability:** No crashes during 30+ minute sessions
- ✅ **Battery:** < 10% additional drain per hour
- ✅ **Memory:** Stable, no leaks

---

## Reporting Issues

If you encounter problems, note:

1. Which test failed
2. Console logs (last 50 lines)
3. Device models and OS versions
4. Steps to reproduce
5. Screenshots if applicable
