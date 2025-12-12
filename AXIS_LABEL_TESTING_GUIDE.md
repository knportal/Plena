# Axis Label Testing Guide - Option C Implementation

## Overview

Both axis label implementations are now available in the codebase. You can test and compare them easily.

## Files Created

1. **PlenaTimeAxisLabels.swift** - New separate view approach
2. **AxisLabelImplementation.swift** - Feature flag enum
3. **AxisLabelTestView.swift** - Test view for side-by-side comparison
4. **AxisLabelSettingsView.swift** - Settings view to toggle implementations

## How to Test

### Method 1: Using the Test View (Recommended)

1. **Run the app in DEBUG mode**
2. **Navigate to the "Axis Test" tab** (added to ContentView in DEBUG builds)
3. **Use the picker** to switch between:
   - Chart Integrated (current implementation)
   - Separate View (new implementation)
4. **Change time ranges** (Day/Week/Month/Year) to see how each handles different ranges
5. **Compare side-by-side** when using Chart Integrated - it shows both implementations

### Method 2: Change Global Setting

In `AxisLabelImplementation.swift`, change:

```swift
var currentAxisLabelImplementation: AxisLabelImplementation = .chartIntegrated
```

to:

```swift
var currentAxisLabelImplementation: AxisLabelImplementation = .separateView
```

This will change all charts throughout the app.

### Method 3: Per-Chart Testing

Each chart component now accepts an `axisImplementation` parameter:

```swift
GraphView(
    // ... other parameters
    axisImplementation: .separateView  // or .chartIntegrated
)
```

## Implementation Details

### Chart Integrated (Current)

- Uses Swift Charts' built-in `AxisMarks`
- Automatically aligns with data points
- Supports rotation, minor ticks, quarter boundaries
- More complex but integrated with Chart framework

### Separate View (New)

- Custom SwiftUI view below the chart
- Simple, predictable label generation
- Full control over spacing and layout
- May require manual alignment adjustments

## What to Test

1. **Label Readability**

   - Are labels clear and not overlapping?
   - Do they align properly with data points?

2. **Consistency**

   - Are labels consistent across Day/Week/Month/Year?
   - Do they match the expected format?

3. **Performance**

   - Does scrolling feel smooth?
   - Any lag when switching time ranges?

4. **Edge Cases**
   - What happens with sparse data?
   - What happens with dense data?
   - Different screen sizes?

## Reverting

If you want to revert to only one implementation:

1. **Keep Chart Integrated**: Remove `PlenaTimeAxisLabels.swift` and related code
2. **Keep Separate View**: Remove `SmartAxisLabelFormatter.swift` usage and keep only `PlenaTimeAxisLabels`

Or simply change the default in `AxisLabelImplementation.swift` to your preferred option.

## Current Default

Default is set to `.chartIntegrated` to maintain current behavior. Change it in `AxisLabelImplementation.swift` if you prefer the new approach.
