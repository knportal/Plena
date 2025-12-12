# Backup: Data Visualization Implementation - Stage 4

**Date:** December 8, 2025
**Stage:** New View Components (Stage 4)
**Status:** Pre-implementation backup

---

## Current State (After Stage 3)

### Files Created in Stage 1

- ✅ `PlenaShared/Services/BaselineCalculationService.swift`
- ✅ `PlenaShared/Models/SessionMetricSummary.swift`
- ✅ `PlenaShared/Models/PeriodScore.swift`
- ✅ `PlenaShared/Models/ZoneSummary.swift`
- ✅ `PlenaShared/Models/TrendStats.swift`
- ✅ `PlenaShared/Services/ZoneClassifier.swift` (extended)

### Files Created in Stage 2

- ✅ `PlenaShared/Services/MetricAggregationService.swift`

### Files Modified in Stage 3

- ✅ `PlenaShared/ViewModels/SensorTypes.swift` (added ViewMode enum)
- ✅ `PlenaShared/ViewModels/DataVisualizationViewModel.swift` (extended)

### Build Status

- ✅ Stage 1 builds successfully
- ✅ Stage 2 builds successfully
- ✅ Stage 3 builds successfully (verified)

---

## Stage 4 Implementation Plan

### New View Components to Create

1. **ConsistencyChartView.swift**

   - Location: `Plena/Views/Components/`
   - Purpose: Bar chart showing period scores with height + color
   - Uses Swift Charts BarMark

2. **TrendInsightCard.swift**

   - Location: `Plena/Views/Components/`
   - Purpose: Insight header card showing trend stats
   - Displays status, delta text, and description

3. **ZoneChipsView.swift**

   - Location: `Plena/Views/Components/`
   - Purpose: Zone percentage chips (🟩 Calm: 61%, etc.)

4. **MetricSelectorView.swift**

   - Location: `Plena/Views/Components/`
   - Purpose: Updated metric selector with icons and subtitles
   - Shows HRV → "Recovery", HR → "Calmness", Respiration → "Breath Depth"

5. **ViewModeToggle.swift**
   - Location: `Plena/Views/Components/`
   - Purpose: Segmented control for Consistency/Trend toggle

---

## Integration Notes

- Components will use ViewModel's new computed properties
- Will integrate with existing DataVisualizationView
- Will maintain existing functionality while adding new features
- Components are reusable and testable

---

## Rollback Plan

If issues arise, Stage 4 can be reverted by:

1. Deleting new component files
2. No existing files are modified in Stage 4

---

**Backup Complete - Ready for Stage 4 Implementation**
