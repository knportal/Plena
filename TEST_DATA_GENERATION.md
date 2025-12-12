# Test Data Generation

## Overview

A test data generation system has been created to help you see the dashboard in action with realistic meditation session data.

---

## What Was Created

### 1. **TestDataGenerator Service** ✅
**File**: `PlenaShared/Services/TestDataGenerator.swift`

A service that generates realistic meditation sessions with:
- Varied dates over the past 30 days
- Realistic durations (10-25 minutes)
- Different times of day (weighted toward morning/evening)
- Complete sensor data (heart rate, HRV, respiratory rate)
- Progressive patterns (more frequent in recent days)

**Key Methods**:
- `generateSession()` - Creates a single session
- `generateRealisticTestData()` - Creates ~30 sessions with realistic patterns
- `populateTestData()` - Saves generated data to storage

### 2. **TestDataView** ✅
**File**: `Plena/Views/TestDataView.swift`

A debug/development view that lets you:
- Generate test data with one tap
- See current session count
- Clear all sessions (if needed)
- Understand what test data includes

**Available in**: Debug builds only (wrapped in `#if DEBUG`)

---

## How to Use

### Generate Test Data

1. **Run app in Debug mode**
2. **Navigate to "Test Data" tab** (4th tab, only visible in debug)
3. **Tap "Generate Test Data" button**
4. **Wait a few seconds** for generation to complete
5. **Navigate to Dashboard tab** to see the data!

### What Gets Generated

The test data includes approximately **25-30 sessions** with:

- **Date Range**: Past 30 days
- **Frequency Pattern**:
  - Last 7 days: ~4-5 sessions (60% daily chance)
  - Days 7-14: ~2-3 sessions (40% daily chance)
  - Days 14-30: ~4-6 sessions (30% daily chance)
- **Duration**:
  - Recent: 18-25 minutes
  - Older: 10-18 minutes
- **Times**: Weighted toward:
  - Morning (9am) - Most popular
  - Evening (6-8pm)
  - Early morning (7am)
  - Occasional midday/night
- **Sensor Data**:
  - Heart rate samples (1 per minute)
  - HRV samples (1 per minute)
  - Respiratory rate samples (1 per minute)
  - Realistic values with gradual changes during meditation

---

## Test Data Characteristics

### Realistic Patterns

1. **Building Habit**: More sessions in recent days
2. **Time Preferences**: Morning sessions most common
3. **Duration Trends**: Longer sessions as habit builds
4. **Sensor Trends**:
   - Heart rate decreases during meditation
   - HRV increases during meditation
   - Respiratory rate slows down

### Example Session Distribution

```
Day 0 (Today):    1 session
Day 1 (Yesterday): 1 session
Day 2:            0 sessions
Day 3:            1 session
Day 4:            1 session
Day 5:            0 sessions
Day 6:            1 session
... (continues back 30 days)
```

This creates a realistic "building habit" pattern visible in the dashboard.

---

## Dashboard Features You'll See

With test data, you can explore:

### Stat Cards
- **Total Sessions**: ~25-30
- **Total Time**: ~6-8 hours
- **Current Streak**: 3-7 days (depends on random generation)
- **Average Duration**: ~18-20 minutes

### Charts
- **Session Frequency**: Bar chart showing sessions over time
- **Duration Trend**: Line chart showing improving duration over time

### Insights
- **Longest Session**: ~25 minutes
- **Best Time**: Morning (typically)
- **This Week**: ~4-5 sessions
- **Per Week Average**: ~5 sessions

---

## Clearing Test Data

To start fresh:

1. Go to "Test Data" tab
2. Tap "Clear All Sessions"
3. Confirm action
4. All sessions will be deleted

**Note**: This clears ALL sessions, not just test data. Use with caution!

---

## Customization

You can modify the test data generation in `TestDataGenerator.swift`:

- Change `daysBack` (default: 30)
- Adjust frequency percentages
- Modify duration ranges
- Change time preferences
- Enable/disable sensor data

---

## Development Notes

### Debug-Only Feature

The Test Data tab is only visible in DEBUG builds:
```swift
#if DEBUG
TestDataView()
    .tabItem {
        Label("Test Data", systemImage: "wrench.and.screwdriver")
    }
    .tag(3)
#endif
```

This ensures it won't appear in production/release builds.

### Performance

Generating test data with sensor samples can take a few seconds:
- ~30 sessions
- ~10-25 samples per session
- = ~300-750 total samples to create and save

Be patient during generation!

---

## Example: Testing Dashboard Features

1. **Generate test data**
2. **Open Dashboard tab**
3. **Change time ranges**:
   - Day: See today's sessions
   - Week: See last 7 days pattern
   - Month: See full 30-day pattern
   - Year: See only recent data (rest is empty)
4. **Check insights**:
   - Longest session
   - Best time of day
   - Weekly patterns
5. **View charts**:
   - Frequency bar chart
   - Duration trend line

---

## Troubleshooting

### "No data available"
- Generate test data first
- Check that you're on the correct time range
- Verify storage service is working

### "Generation failed"
- Check console for errors
- Ensure storage service is properly initialized
- Try clearing all data and regenerating

### Charts not showing
- Need at least 2 sessions with data
- Check time range includes generated dates
- Verify sensor data was included in generation

---

## Future Enhancements

Potential improvements:
- Customizable generation parameters
- Different patterns (streaks, gaps, etc.)
- Export/import test data
- Pre-built data sets for different scenarios

---

**Ready to generate test data and explore the dashboard!** 🎉


