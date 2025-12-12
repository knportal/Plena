# Session Statistics Dashboard - Design Description

## Overview

A comprehensive dashboard that provides users with meaningful insights about their meditation practice over time. The dashboard shows session statistics, trends, patterns, and progress indicators in an easy-to-understand, visually appealing format.

---

## Layout Structure

### Overall Design Philosophy
- **Clean & Minimal**: Meditation-focused design with breathing room
- **Information Hierarchy**: Most important metrics prominently displayed
- **Quick Glance**: Key stats visible at a glance
- **Drill Down**: Ability to explore details when needed
- **Progress Focused**: Emphasis on growth and consistency

---

## Main Dashboard View

### Top Section: Quick Stats Cards

**4-6 Stat Cards in a Grid Layout** (2 columns on iPhone, 3 on iPad)

#### 1. **Total Sessions Card**
- **Icon**: Calendar or stacked circles
- **Large Number**: Total sessions in selected time period
- **Label**: "Sessions" or "Meditation Sessions"
- **Subtitle**: Comparison to previous period
  - "↑ +12 vs last month" (green)
  - "→ Same as last week" (gray)
  - "↓ -3 vs last month" (red)

#### 2. **Total Minutes Card**
- **Icon**: Clock or timer
- **Large Number**: Total meditation time (e.g., "124 hrs" or "7,440 min")
- **Label**: "Total Time" or "Meditation Time"
- **Subtitle**: Average per session
  - "Avg: 15 min/session"

#### 3. **Current Streak Card**
- **Icon**: Fire/flame
- **Large Number**: Current streak count (e.g., "7 days")
- **Label**: "Day Streak"
- **Subtitle**: Motivation text
  - "Keep it up! 🔥"
  - "You're on fire!"

#### 4. **Average Session Duration Card**
- **Icon**: Clock face or hourglass
- **Large Number**: Average length (e.g., "18 min")
- **Label**: "Avg Duration"
- **Subtitle**: Trend indicator
  - "↑ +2 min vs last week"

#### 5. **Sessions This Week Card**
- **Icon**: Calendar grid
- **Large Number**: Sessions in current week
- **Label**: "This Week"
- **Subtitle**: Goal progress (if implemented)
  - "5/7 goal" or "5 sessions"

#### 6. **Best Time Card** (Optional)
- **Icon**: Sun/Moon or clock
- **Large Number/Text**: Most frequent time
- **Label**: "Best Time"
- **Subtitle**: Percentage
  - "Morning (60%)"

---

### Middle Section: Visual Charts & Trends

#### Chart 1: Session Frequency Chart (Bar Chart)
- **Title**: "Sessions Over Time"
- **Type**: Bar chart (grouped by day/week/month based on time range)
- **X-Axis**: Time periods (dates)
- **Y-Axis**: Number of sessions
- **Visual**:
  - Bars show sessions per period
  - Color-coded (green gradient)
  - Highlights current period

**Time Range Behavior**:
- **Day view**: Hours of day
- **Week view**: Days of week
- **Month view**: Days of month
- **Year view**: Weeks or months

#### Chart 2: Duration Trend (Line Chart)
- **Title**: "Average Session Duration"
- **Type**: Line chart showing trend
- **X-Axis**: Time periods
- **Y-Axis**: Minutes
- **Visual**:
  - Smooth line connecting average durations
  - Optional: Area fill under line
  - Trend indicator (up/down arrow)

#### Chart 3: Total Minutes Chart (Area Chart)
- **Title**: "Total Meditation Time"
- **Type**: Stacked area or cumulative bar
- **Shows**: Cumulative or per-period total minutes
- **Visual**:
  - Filled area showing growth
  - Gradient color
  - Shows progression over time

---

### Bottom Section: Insights & Patterns

#### Insight Cards (Scrollable Horizontal List)

**Card 1: Consistency Score**
- **Visual**: Circular progress indicator
- **Number**: Percentage (e.g., "75%")
- **Label**: "Consistency"
- **Subtitle**: Based on session frequency vs goal
- **Color**: Green (good) / Yellow (ok) / Red (needs work)

**Card 2: Longest Session**
- **Icon**: Trophy or star
- **Number**: "42 min"
- **Label**: "Longest Session"
- **Subtitle**: Date when it occurred
  - "On Jan 15, 2024"

**Card 3: Time Distribution**
- **Visual**: Pie chart or horizontal bars
- **Shows**: Morning / Afternoon / Evening / Night distribution
- **Label**: "Session Times"
- **Subtitle**: "Mostly morning sessions"

**Card 4: Weekly Pattern**
- **Visual**: Mini bar chart (7 bars)
- **Shows**: Sessions per day of week
- **Label**: "Weekly Pattern"
- **Subtitle**: "Most active: Mondays"

**Card 5: Progress Milestone**
- **Visual**: Badge or achievement icon
- **Text**: Milestone reached
  - "100 Sessions! 🎉"
  - "50 Hours Meditated"
- **Subtitle**: Next milestone preview

---

## Time Range Selector

### Top Navigation Bar
- **Segmented Control**: Day / Week / Month / Year / All Time
- **Position**: Below navigation title or in toolbar
- **Behavior**:
  - Changes all charts/stats dynamically
  - Smooth transitions
  - Remembers last selection (optional)

### Comparison Toggle
- **Switch/Button**: "Compare to Previous"
- **Shows**: Side-by-side comparison when enabled
  - Current period vs previous period
  - Percentage changes
  - Visual indicators (↑↓)

---

## Detailed Statistics View (Optional Drill-Down)

### Tappable Cards → Expanded View

When user taps a stat card:

#### Expanded Session Frequency View
- **Full screen or sheet**
- **Detailed breakdown**:
  - List of all sessions in period
  - Timeline view
  - Calendar heat map (sessions per day)
- **Filters**: By duration, time of day, etc.

#### Expanded Duration Analysis
- **Distribution histogram**: Sessions by duration ranges
- **Box plot**: Min, max, median, quartiles
- **Duration goals**: Progress toward target

---

## Visual Design Elements

### Color Scheme
- **Primary**: Green (meditation/calm)
- **Secondary**: Blue (data/analytics)
- **Accent**: Orange/Yellow (achievements/milestones)
- **Neutral**: Gray (backgrounds, borders)
- **Gradient**: Subtle gradients on cards

### Typography
- **Large Numbers**: Bold, system font, 32-48pt
- **Labels**: Regular, 14-16pt
- **Subtitles**: Light/Medium, 12-14pt
- **Charts**: System font with clear labels

### Spacing & Layout
- **Card Padding**: 16-20pt
- **Card Spacing**: 12-16pt
- **Section Spacing**: 24-32pt
- **Edge Padding**: 16-20pt

### Interactive Elements
- **Card Tap**: Subtle scale/opacity animation
- **Chart Interactions**:
  - Tap bar/line to see value
  - Long press for details
  - Pan/zoom on charts (if applicable)

---

## Responsive Design

### iPhone Layout
- **Portrait**:
  - 2 columns for stat cards
  - Stacked charts (full width)
  - Scrollable insights section
- **Landscape**:
  - 3 columns for stat cards
  - Side-by-side charts (if space allows)

### iPad Layout
- **Portrait**:
  - 3-4 columns for stat cards
  - Side-by-side charts
  - More insights visible at once
- **Landscape**:
  - 4-6 columns for stat cards
  - Optimal use of space
  - Split view compatible

### Watch Layout (Future)
- **Simplified view**:
  - Single large stat (current streak)
  - Circular progress for total time
  - Swipe for more stats

---

## Data Calculation Examples

### Current Streak
- Count consecutive days with at least one session
- Reset if gap of 1+ days
- Show longest streak vs current

### Consistency Score
- Formula: (Actual sessions / Target sessions) × 100
- Target: Configurable (e.g., 7 sessions/week)
- Range: 0-100%

### Best Time
- Group sessions by time of day:
  - Morning: 6am - 12pm
  - Afternoon: 12pm - 6pm
  - Evening: 6pm - 10pm
  - Night: 10pm - 6am
- Show highest frequency time period

### Weekly Pattern
- Count sessions per day of week
- Visualize as 7-bar chart
- Highlight most/least active days

---

## User Experience Flow

### Initial Load
1. **Loading State**: Skeleton screens or progress indicator
2. **Default View**: Last 30 days (or user preference)
3. **Auto-refresh**: Update when new session completes

### Navigation Flow
1. **Main Dashboard** → Tap stat card → **Detailed View**
2. **Main Dashboard** → Change time range → **Update all stats**
3. **Main Dashboard** → Swipe insight cards → **Scroll through insights**

### Empty States
- **No Data**:
  - Friendly illustration
  - "Start your first meditation session"
  - CTA button to meditate
- **Not Enough Data**:
  - "Keep meditating to see trends"
  - Show available stats only
  - Hide charts that need more data

### Error States
- **Load Failed**:
  - Error message
  - Retry button
  - Graceful degradation

---

## Accessibility Considerations

### VoiceOver Support
- Clear labels for all stats
- Chart descriptions
- Navigation hints
- Dynamic value announcements

### Dynamic Type
- All text scales with system settings
- Charts remain readable at large sizes
- Layout adapts to text size

### Color Contrast
- WCAG AA compliant
- Not color-only indicators (use icons + color)
- Dark mode support

---

## Example Layout Mockup (Text Description)

```
┌─────────────────────────────────────┐
│  Dashboard                    [⚙️]  │
│  [Day] [Week] [Month] [Year]       │
├─────────────────────────────────────┤
│                                     │
│  ┌──────────┐  ┌──────────┐       │
│  │   45     │  │  124 hrs │       │
│  │ Sessions │  │ Total    │       │
│  │ ↑ +12    │  │ Avg: 15m │       │
│  └──────────┘  └──────────┘       │
│                                     │
│  ┌──────────┐  ┌──────────┐       │
│  │   7 days │  │   18 min │       │
│  │ Streak 🔥│  │ Avg      │       │
│  │ Keep it  │  │ ↑ +2 min │       │
│  └──────────┘  └──────────┘       │
│                                     │
│  ┌───────────────────────────┐    │
│  │  Sessions Over Time       │    │
│  │  ▁▃▅▇█▇▅▃▁▃▅▇█▇▅▃        │    │
│  │   M T W T F S S           │    │
│  └───────────────────────────┘    │
│                                     │
│  ┌───────────────────────────┐    │
│  │  Duration Trend           │    │
│  │    ╱╲                     │    │
│  │   ╱  ╲    ╱╲              │    │
│  │  ╱    ╲╱╱  ╲              │    │
│  └───────────────────────────┘    │
│                                     │
│  Insights →                        │
│  [Consistency] [Longest] [Times]   │
│                                     │
└─────────────────────────────────────┘
```

---

## Statistics to Calculate

### Primary Metrics
1. **Total Sessions** (in time range)
2. **Total Minutes/Hours** (cumulative)
3. **Average Duration** (mean)
4. **Current Streak** (consecutive days)
5. **Sessions This Week** (current week)

### Secondary Metrics
6. **Longest Session** (maximum duration)
7. **Shortest Session** (minimum duration)
8. **Median Duration** (middle value)
9. **Total Sessions All Time** (lifetime)
10. **Sessions Per Week** (average frequency)

### Advanced Metrics
11. **Consistency Score** (vs goal)
12. **Best Time of Day** (most frequent)
13. **Weekly Pattern** (day distribution)
14. **Progress Rate** (sessions/day trend)
15. **Milestone Progress** (toward next goal)

---

## Comparison Features

### Period Comparison
- **Compare to Previous**:
  - Same period length (e.g., this month vs last month)
  - Show percentage change
  - Visual indicators (↑↓→)

### Goal Tracking (Optional)
- **Set Goals**:
  - Sessions per week/month
  - Minutes per week/month
  - Daily streak target
- **Progress Bars**:
  - Visual progress toward goal
  - Time remaining indicator
  - Celebration when achieved

---

## Animation & Transitions

### Data Updates
- **Smooth Transitions**: Stats count up to new values
- **Chart Animations**: Bars/lines animate in
- **Loading States**: Skeleton screens or shimmer

### Interactions
- **Card Tap**: Scale down slightly, reveal details
- **Swipe**: Smooth horizontal scrolling for insights
- **Pull to Refresh**: Standard iOS pattern

---

## Integration Points

### With Existing Views
- **Navigation**: Add as new tab or section in existing visualization view
- **Deep Links**: From achievements, notifications, etc.
- **Share**: Export stats as image or report

### With HealthKit Data
- **Query Sessions**: Use `fetchMindfulSessions()` for historical data
- **Combine Sources**: Merge HealthKit + local storage
- **Sync Status**: Show last sync time

---

## Technical Implementation Notes

### Data Sources
- **Local Storage**: Detailed session data (sensor samples, etc.)
- **HealthKit**: Lightweight session markers (start/end times)
- **Combined Query**: Merge both sources for complete picture

### Performance
- **Lazy Loading**: Load charts as needed
- **Caching**: Cache calculated stats
- **Background Updates**: Refresh in background

### State Management
- **ObservableObject**: ViewModel with @Published properties
- **Async Loading**: Load data asynchronously
- **Error Handling**: Graceful error states

---

## Future Enhancements (Phase 2+)

1. **Personalized Insights**: AI-generated tips based on patterns
2. **Social Sharing**: Share stats/milestones (privacy-conscious)
3. **Export Reports**: PDF/weekly summaries
4. **Goal Recommendations**: Suggest goals based on history
5. **Notifications**: Reminders based on patterns
6. **Comparisons**: Compare with averages (anonymous)
7. **Achievements**: Badges for milestones

---

## Summary

A comprehensive, visually appealing dashboard that gives users:

✅ **Quick Overview**: Key stats at a glance
✅ **Visual Trends**: Charts showing progress over time
✅ **Meaningful Insights**: Patterns and consistency metrics
✅ **Progress Tracking**: Streaks, milestones, goals
✅ **Flexible Views**: Different time ranges for different insights
✅ **Beautiful Design**: Meditation-focused, calming aesthetic

The dashboard transforms raw session data into actionable insights, helping users understand their practice, stay motivated, and build consistent meditation habits.

---

*Ready for implementation once design is approved*


