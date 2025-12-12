# Backup: Data Visualization Implementation - Stage 3

**Date:** December 8, 2025
**Stage:** ViewModel Extension (Stage 3)
**Status:** Pre-implementation backup

---

## Current State (After Stage 2)

### Files Created in Stage 1

- ✅ `PlenaShared/Services/BaselineCalculationService.swift`
- ✅ `PlenaShared/Models/SessionMetricSummary.swift`
- ✅ `PlenaShared/Models/PeriodScore.swift`
- ✅ `PlenaShared/Models/ZoneSummary.swift`
- ✅ `PlenaShared/Models/TrendStats.swift`
- ✅ `PlenaShared/Services/ZoneClassifier.swift` (extended)

### Files Created in Stage 2

- ✅ `PlenaShared/Services/MetricAggregationService.swift`

### Build Status

- ✅ Stage 1 builds successfully
- ✅ Stage 2 builds successfully (verified)

---

## Stage 3 Implementation Plan

### Files to Modify

**DataVisualizationViewModel.swift**

- Location: `PlenaShared/ViewModels/` (modify existing)
- Add: ViewMode enum (if not exists)
- Add: @Published var viewMode
- Add: Dependencies (BaselineCalculationService, MetricAggregationService, ZoneClassifier)
- Add: Computed properties for period scores
- Add: Computed properties for zone summaries
- Add: Computed properties for trend stats
- Add: Baseline calculation methods
- Keep: All existing functionality intact

---

## New Properties to Add

1. **ViewMode State**

   - `@Published var viewMode: ViewMode`
   - Default based on time range (Consistency for Week/Month, Trend for Day/Year)

2. **Service Dependencies**

   - `baselineService: BaselineCalculationServiceProtocol`
   - `aggregationService: MetricAggregationServiceProtocol`
   - `zoneClassifier: ZoneClassifierProtocol`

3. **Computed Properties**
   - `periodScores: [PeriodScore]` - For consistency chart
   - `zoneSummaries: [ZoneSummary]` - For zone chips
   - `trendStats: TrendStats?` - For insight header
   - `hrvBaseline: Double?` - Cached baseline
   - `restingHR: Double?` - Cached resting HR

---

## Implementation Notes

- All new properties will be computed/lazy to avoid breaking existing code
- Baseline calculation will be cached and recalculated when sessions change
- ViewMode default logic: Week/Month = Consistency, Day/Year = Trend
- Existing data extraction methods remain unchanged

---

## Rollback Plan

If issues arise, Stage 3 can be reverted by:

1. Reverting DataVisualizationViewModel.swift to original state
2. No other files are modified in Stage 3

---

**Backup Complete - Ready for Stage 3 Implementation**
