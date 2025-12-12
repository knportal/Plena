# Backup: Data Visualization Implementation - Stage 5

**Date:** December 8, 2025
**Stage:** Integration (Stage 5)
**Status:** Pre-implementation backup

---

## Current State (After Stage 4)

### All Previous Stages Complete

- ✅ Stage 1: Foundation services and models
- ✅ Stage 2: Aggregation service
- ✅ Stage 3: ViewModel extended
- ✅ Stage 4: View components created
- ✅ All stages build successfully

---

## Stage 5 Implementation Plan

### File to Modify

**DataVisualizationView.swift**

- Location: `Plena/Views/` (modify existing)
- Integrate new components into existing view

### Integration Steps

1. **Replace sensor selector** with `MetricSelectorView`

   - Keep enabled sensors filtering
   - Use new component with icons and subtitles

2. **Add TrendInsightCard** below time range selector

   - Only show for supported metrics (HRV, HR, Respiration)
   - Show nil state gracefully

3. **Add ViewModeToggle** below insight card

   - Only show for supported metrics
   - Bind to viewModel.viewMode

4. **Add conditional chart display:**

   - If `viewMode == .consistency` → Show `ConsistencyChartView`
   - If `viewMode == .trend` → Show existing `GraphView`
   - Only for supported metrics

5. **Add ZoneChipsView** below chart

   - Only show for supported metrics
   - Show in consistency mode

6. **Keep existing stats row** (min/max/avg)
   - Works for all metrics

---

## Backward Compatibility

- VO₂ Max and Temperature will continue using existing GraphView
- Existing functionality preserved
- New features only for HRV, HR, Respiration

---

## Rollback Plan

If issues arise, Stage 5 can be reverted by:

1. Reverting DataVisualizationView.swift to original state
2. All component files remain (can be used later)

---

**Backup Complete - Ready for Stage 5 Integration**
