# Backup: Before Live Sensor Sync Implementation

**Date:** 2025-12-28 17:13:44
**Change:** Implementing live sensor data sync from Watch to iPhone via WatchConnectivity

## Current State

### Architecture

- iPhone queries HealthKit directly for sensor data during sessions
- Watch queries HealthKit independently
- Only completed sessions sync from Watch to iPhone (via applicationContext)
- No real-time data streaming during active sessions

### Known Issues

- HealthKit sync delay (2-5+ seconds)
- "Watch and iPhone show different data" problem
- No live updates on iPhone during watch sessions
- Cannot start sessions from either device

### Files to be Modified

1. `PlenaShared/Services/WatchConnectivityService.swift`

   - Add LiveSensorSample model
   - Add sendLiveSample() and onLiveSampleReceived() methods
   - Add meditation session coordination
   - Add didReceiveMessageData delegate method

2. `PlenaShared/ViewModels/MeditationSessionViewModel.swift`

   - Add live sample sending on watchOS
   - Add live sample receiving on iOS
   - Add duplicate data prevention
   - Add timeout monitoring

3. `Plena Watch App/Views/MeditationWatchView.swift`
   - Add meditation session request handler

## Implementation Plan

1. Add LiveSensorSample model to WatchConnectivityService
2. Extend WatchConnectivityServiceProtocol with live sample methods
3. Implement sendLiveSample() on watchOS
4. Implement onLiveSampleReceived() on iOS
5. Add meditation session coordination
6. Update MeditationSessionViewModel to send/receive live samples
7. Add fallback and error handling
8. Update watch view to handle meditation session requests
