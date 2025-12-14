# Backup: Data Visualization Implementation - Stage 2

**Date:** December 8, 2025
**Stage:** Aggregation Logic (Stage 2)
**Status:** Pre-implementation backup

---

## Current State (After Stage 1)

### Files Created in Stage 1

- ✅ `PlenaShared/Services/BaselineCalculationService.swift`
- ✅ `PlenaShared/Models/SessionMetricSummary.swift`
- ✅ `PlenaShared/Models/PeriodScore.swift`
- ✅ `PlenaShared/Models/ZoneSummary.swift`
- ✅ `PlenaShared/Models/TrendStats.swift`
- ✅ `PlenaShared/Services/ZoneClassifier.swift` (extended)

### Build Status

- ✅ Stage 1 builds successfully (verified in separate thread)

---

## Stage 2 Implementation Plan

### New File to Create

**MetricAggregationService.swift**

- Location: `PlenaShared/Services/`
- Purpose: Convert raw session data into aggregated metrics for visualization

### Functions to Implement

1. **Session → SessionMetricSummary**

   - `createSessionMetricSummary()` - Convert single session to summary
   - Processes samples, calculates zone fractions, determines dominant zone

2. **Period Grouping**

   - `groupSessionsByPeriod()` - Group sessions by day/week/month
   - Returns dictionary of period label → sessions

3. **PeriodScore Calculation**

   - `createPeriodScore()` - Convert session group to PeriodScore
   - Calculates calm score (0-100) and dominant zone

4. **ZoneSummary Calculation**

   - `createZoneSummaries()` - Calculate zone percentages across all sessions
   - Returns array of ZoneSummary for chips

5. **TrendStats Calculation**
   - `createTrendStats()` - Compare current vs previous period
   - Returns TrendStats with status, delta, and description

---

## Dependencies

- `BaselineCalculationService` - For baseline calculations
- `ZoneClassifier` - For zone classification
- `SessionStorageServiceProtocol` - For loading previous period data
- Models from Stage 1: `SessionMetricSummary`, `PeriodScore`, `ZoneSummary`, `TrendStats`

---

## Implementation Notes

- All functions will be protocol-based for testability
- Will handle edge cases (empty sessions, no baseline, etc.)
- Will use existing `TimeRange` enum for period logic
- Will use existing `SensorType` enum (focusing on HRV, HR, Respiration)

---

## Rollback Plan

If issues arise, Stage 2 can be reverted by:

1. Deleting `MetricAggregationService.swift`
2. No other files are modified in Stage 2

---

**Backup Complete - Ready for Stage 2 Implementation**


