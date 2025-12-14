# Data Persistence Migration: JSON → SwiftData/Core Data

## Recommendation: **SwiftData** (with iOS 17+ requirement)

### Why SwiftData for Scaling

1. **Modern & Future-Proof**

   - Swift-native API (no Objective-C bridging)
   - Built on Core Data but with simpler syntax
   - Apple's recommended path forward
   - Better SwiftUI integration

2. **CloudKit Sync Built-In**

   - Automatic iCloud sync between iPhone and Watch
   - No manual App Group file sharing needed
   - Handles conflicts automatically

3. **Performance at Scale**

   - Lazy loading of relationships
   - Efficient queries with predicates
   - Background context support
   - Handles thousands of sessions with millions of samples

4. **Less Code**
   - ~70% less boilerplate than Core Data
   - Type-safe queries
   - Automatic migration support

### Trade-off: iOS 17.0+ Required

- **Current requirement**: iOS 16.0+
- **SwiftData requirement**: iOS 17.0+
- **Recommendation**: Bump minimum to iOS 17.0+ for better long-term maintainability

**Alternative**: Use Core Data if you must support iOS 16 (see Core Data option below)

---

## HealthKit Historical Data Import

### ✅ Yes, You Can Import Existing HealthKit Data

Your current `HealthKitService` only queries real-time data. We need to add historical data import.

### What Can Be Imported

1. **Heart Rate Samples**

   - All historical heart rate readings from Apple Watch/iPhone
   - Can filter by date range
   - Can group into meditation sessions by time windows

2. **HRV (SDNN) Samples**

   - Historical HRV measurements
   - Typically measured during workouts/meditation

3. **Respiratory Rate**
   - Historical respiratory rate data
   - Available from Apple Watch Series 6+

### Import Strategy

1. **Query Historical Data**

   - Use `HKSampleQuery` to fetch samples by date range
   - Filter samples that might correspond to meditation periods
   - Group samples into potential meditation sessions

2. **Smart Session Detection**

   - Look for periods of:
     - Lower heart rate variability
     - Consistent respiratory rate
     - Extended time periods (10+ minutes)
   - Or allow manual session creation from date ranges

3. **Batch Import**
   - Import in background to avoid blocking UI
   - Show progress indicator
   - Allow user to cancel

---

## Implementation Plan

### Phase 1: SwiftData Model Setup

1. Create SwiftData models:

   - `MeditationSession` (with relationships)
   - `HeartRateSample`
   - `HRVSample`
   - `RespiratoryRateSample`
   - `StateOfMindLog`

2. Set up ModelContainer in app entry point

3. Configure CloudKit sync (optional but recommended)

### Phase 2: Historical HealthKit Import

1. Extend `HealthKitService` with:

   - `fetchHistoricalHeartRate(startDate:endDate:)`
   - `fetchHistoricalHRV(startDate:endDate:)`
   - `fetchHistoricalRespiratoryRate(startDate:endDate:)`

2. Create `HealthKitImportService`:
   - Batch import functionality
   - Session detection logic
   - Progress tracking

### Phase 3: Migration from JSON

1. Create migration service:

   - Read existing `meditation_sessions.json`
   - Convert to SwiftData models
   - Preserve all existing data

2. One-time migration on first launch after update

### Phase 4: Update Storage Service

1. Replace `SessionStorageService` with SwiftData-based service
2. Update ViewModels to use new storage
3. Maintain protocol for testability

---

## Core Data Alternative (iOS 16 Support)

If you must support iOS 16, use Core Data instead:

### Differences

- More verbose code (NSManagedObject subclasses)
- Manual CloudKit setup required
- More complex migration handling
- But: Works on iOS 16.0+

### Implementation Similarity

- Same data model structure
- Same HealthKit import logic
- Same migration path from JSON
- Just different persistence API

---

## Next Steps

1. **Decide**: SwiftData (iOS 17+) or Core Data (iOS 16+)
2. **Implement**: Historical HealthKit import
3. **Migrate**: JSON data to new persistence layer
4. **Test**: With large datasets (100+ sessions, 10k+ samples)



