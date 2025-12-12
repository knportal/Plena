# Backup: Data Visualization Implementation - Stage 1

**Date:** December 8, 2025
**Stage:** Foundation (Stage 1)
**Status:** Pre-implementation backup

---

## Overview

This backup documents the state of the project before implementing Stage 1 of the new Data Visualization feature. Stage 1 focuses on creating foundational services and models without modifying existing UI.

---

## Current State

### Existing Files (Unchanged)

- `PlenaShared/Services/ZoneClassifier.swift` - Zone classification for HRV and Heart Rate
- `PlenaShared/Models/StressZone.swift` - Zone enum (calm, optimal, elevatedStress)
- `PlenaShared/ViewModels/DataVisualizationViewModel.swift` - Existing data visualization logic
- `Plena/Views/DataVisualizationView.swift` - Existing UI (will remain unchanged)

### Existing Models

- `MeditationSession` - Session data with sample arrays
- `HRVSample`, `HeartRateSample`, `RespiratoryRateSample` - Sample types
- `SensorType` enum - All 5 sensor types
- `TimeRange` enum - Day, Week, Month, Year

---

## Stage 1 Implementation Plan

### New Files to Create

1. **BaselineCalculationService.swift**

   - Location: `PlenaShared/Services/`
   - Purpose: Calculate user baselines (30-day HRV median, resting HR)
   - Dependencies: `SessionStorageServiceProtocol`

2. **Extended ZoneClassifier**

   - File: `PlenaShared/Services/ZoneClassifier.swift` (modify existing)
   - Add: `classifyRespiratoryRate()` method
   - Add: Baseline-aware HRV classification
   - Add: Resting HR-aware Heart Rate classification

3. **SessionMetricSummary.swift**

   - Location: `PlenaShared/Models/`
   - Purpose: Session-level metric aggregation with zone fractions

4. **PeriodScore.swift**

   - Location: `PlenaShared/Models/`
   - Purpose: Period-level data for consistency charts

5. **ZoneSummary.swift**

   - Location: `PlenaShared/Models/`
   - Purpose: Zone percentage summaries

6. **TrendStats.swift**
   - Location: `PlenaShared/Models/`
   - Purpose: Period-over-period comparison data

---

## Zone Thresholds (From Spec)

### HRV (Relative to Baseline)

- **Calm/Optimal:** `hrv > baselineHRV + (baselineHRV * 0.15)`
- **Neutral:** `baselineHRV - (baselineHRV * 0.15) ... baselineHRV + (baselineHRV * 0.15)`
- **Stress/Low:** `hrv < baselineHRV - (baselineHRV * 0.15)`
- **Fallback (no baseline):** < 25ms = Stress, 25-45ms = Neutral, > 45ms = Calm

### Heart Rate (Relative to Resting HR)

- **Calm:** `sessionHR <= restingHR + 5`
- **Neutral:** `restingHR + 5 < sessionHR <= restingHR + 20`
- **Elevated:** `sessionHR > restingHR + 20`
- **Fallback:** Use existing ZoneClassifier logic

### Respiration (Absolute)

- **Calm/Deep:** 6-12 breaths/min
- **Normal:** 12-16 breaths/min
- **Fast/Shallow:** > 16 breaths/min

---

## Implementation Notes

- All new files are additive (no breaking changes)
- ZoneClassifier extension maintains backward compatibility
- Existing StressZone enum will be used (no new zone types)
- Baseline calculation will be on-demand (no caching in Stage 1)

---

## Rollback Plan

If issues arise, Stage 1 can be reverted by:

1. Deleting new model files
2. Reverting ZoneClassifier.swift to original state
3. Deleting BaselineCalculationService.swift

No existing functionality will be affected.

---

**Backup Complete - Ready for Stage 1 Implementation**
