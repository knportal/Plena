# Readiness Score Feature Implementation Plan

## Overview

This document outlines the implementation plan for adding a **Readiness Score** feature to Plena, inspired by health tracking apps like Oura Ring and Whoop. The readiness score provides users with a daily assessment of their body's readiness for meditation based on multiple biometric contributors.

## Feature Goals

1. **Daily Readiness Score**: A single score (0-100) representing overall readiness for meditation
2. **Contributor Metrics**: Breakdown showing which factors contribute to the score
3. **Visual Feedback**: Progress bars and color-coded status indicators
4. **Historical Comparison**: Compare today's readiness to yesterday
5. **Actionable Insights**: Clear indicators of what needs attention

## Architecture

### Components to Create

1. **Models** (`PlenaShared/Models/`)
   - `ReadinessScore.swift` - Core readiness score calculation
   - `ReadinessContributor.swift` - Individual metric contributor
   - `ReadinessStatus.swift` - Status enum (Optimal, Good, Pay Attention)

2. **Services** (`PlenaShared/Services/`)
   - `ReadinessScoreService.swift` - Business logic for calculating readiness

3. **ViewModels** (`PlenaShared/ViewModels/`)
   - `ReadinessViewModel.swift` - MVVM view model for readiness data

4. **Views** (`Plena/Views/`)
   - `ReadinessView.swift` - Main readiness dashboard view
   - `ReadinessContributorRow.swift` - Individual contributor row component
   - `ReadinessScoreCard.swift` - Main score display card

## Implementation Steps

### Phase 1: Data Models & Calculation Logic

#### Step 1.1: Create Readiness Contributor Model

**File**: `PlenaShared/Models/ReadinessContributor.swift`

```swift
import Foundation

/// Represents a single metric that contributes to the readiness score
struct ReadinessContributor: Identifiable {
    let id: UUID
    let name: String
    let value: String // e.g., "64 bpm", "Good", "Optimal"
    let status: ReadinessStatus
    let score: Double // 0.0-1.0 contribution to overall score
    let progress: Double // 0.0-1.0 for progress bar

    var icon: String {
        switch name {
        case "Resting heart rate": return "heart.fill"
        case "HRV balance": return "waveform.path.ecg"
        case "Body temperature": return "thermometer"
        case "Recovery index": return "arrow.triangle.2.circlepath"
        case "Sleep": return "moon.fill"
        case "Sleep balance": return "moon.stars.fill"
        case "Sleep regularity": return "calendar"
        case "Previous day activity": return "figure.walk"
        case "Activity balance": return "scalemass"
        default: return "circle.fill"
        }
    }
}

enum ReadinessStatus: String {
    case optimal = "Optimal"
    case good = "Good"
    case payAttention = "Pay attention"
    case poor = "Poor"

    var color: Color {
        switch self {
        case .optimal: return .green
        case .good: return .blue
        case .payAttention: return .orange
        case .poor: return .red
        }
    }

    var scoreWeight: Double {
        switch self {
        case .optimal: return 1.0
        case .good: return 0.75
        case .payAttention: return 0.5
        case .poor: return 0.25
        }
    }
}
```

#### Step 1.2: Create Readiness Score Model

**File**: `PlenaShared/Models/ReadinessScore.swift`

```swift
import Foundation

/// Represents a daily readiness score with all contributors
struct ReadinessScore: Identifiable {
    let id: UUID
    let date: Date
    let overallScore: Double // 0-100
    let contributors: [ReadinessContributor]

    init(
        id: UUID = UUID(),
        date: Date,
        overallScore: Double,
        contributors: [ReadinessContributor]
    ) {
        self.id = id
        self.date = date
        self.overallScore = overallScore
        self.contributors = contributors
    }

    var status: ReadinessStatus {
        switch overallScore {
        case 80...100: return .optimal
        case 60..<80: return .good
        case 40..<60: return .payAttention
        default: return .poor
        }
    }
}
```

#### Step 1.3: Create Readiness Score Service

**File**: `PlenaShared/Services/ReadinessScoreService.swift`

This service will:
- Calculate resting heart rate from recent sessions
- Calculate HRV balance (variability vs baseline)
- Get body temperature from HealthKit
- Calculate recovery index from recent meditation patterns
- Integrate sleep data (if available from HealthKit)
- Calculate activity balance from previous day

**Key Calculation Methods**:

1. **Resting Heart Rate**: Average heart rate from last 3 sessions' start (first 2 minutes)
2. **HRV Balance**: Compare current week's average HRV to baseline
3. **Body Temperature**: Latest temperature reading vs normal range
4. **Recovery Index**: Based on recent session frequency and duration trends
5. **Sleep Metrics**: If HealthKit sleep data available, calculate sleep quality metrics
6. **Activity Balance**: Based on previous day's meditation activity

### Phase 2: ViewModel Implementation

#### Step 2.1: Create Readiness ViewModel

**File**: `PlenaShared/ViewModels/ReadinessViewModel.swift`

**Responsibilities**:
- Load readiness data for selected date
- Calculate contributors from available data
- Compare today vs yesterday
- Handle date navigation
- Manage loading/error states

**Key Properties**:
- `@Published var readinessScore: ReadinessScore?`
- `@Published var yesterdayScore: ReadinessScore?`
- `@Published var selectedDate: Date`
- `@Published var isLoading: Bool`
- `@Published var errorMessage: String?`

**Key Methods**:
- `func loadReadinessScore(for date: Date) async`
- `func calculateContributors(for date: Date) -> [ReadinessContributor]`
- `func calculateOverallScore(from contributors: [ReadinessContributor]) -> Double`

### Phase 3: UI Components

#### Step 3.1: Readiness Contributor Row Component

**File**: `Plena/Views/Components/ReadinessContributorRow.swift`

**Features**:
- Metric name and value/status
- Horizontal progress bar with color coding
- Right arrow for detail navigation
- Status badge

#### Step 3.2: Readiness Score Card

**File**: `Plena/Views/Components/ReadinessScoreCard.swift`

**Features**:
- Large score display (0-100)
- Status indicator
- Comparison to yesterday
- Circular progress indicator (optional)

#### Step 3.3: Main Readiness View

**File**: `Plena/Views/ReadinessView.swift`

**Layout**:
- Navigation bar with back button and share icon
- Date selector (Yesterday/Today)
- Main score card
- Contributors section with list of metrics
- Detail navigation for each contributor

### Phase 4: Integration

#### Step 4.1: Add to Tab Navigation

Update `ContentView.swift` to add a new "Readiness" tab (or integrate into Dashboard)

**Option A**: New Tab
- Add as 5th tab in TabView
- Icon: `leaf` or `heart.text.square`

**Option B**: Dashboard Integration
- Add as a section at the top of DashboardView
- Link to full ReadinessView

#### Step 4.2: HealthKit Sleep Data Integration

If sleep data is available:
- Request HealthKit sleep analysis permissions
- Calculate sleep duration, balance, and regularity
- Include in readiness calculation

### Phase 5: Calculation Algorithms

#### Resting Heart Rate Calculation
```swift
func calculateRestingHeartRate(from sessions: [MeditationSession]) -> Double? {
    // Get last 3 sessions
    // Extract heart rate from first 2 minutes of each
    // Average the values
    // Compare to user's baseline (if available)
}
```

#### HRV Balance Calculation
```swift
func calculateHRVBalance(currentWeek: [MeditationSession], baseline: Double) -> ReadinessStatus {
    // Calculate average HRV for current week
    // Compare to baseline (user's historical average)
    // Determine status based on deviation
}
```

#### Recovery Index Calculation
```swift
func calculateRecoveryIndex(recentSessions: [MeditationSession]) -> ReadinessStatus {
    // Analyze session frequency
    // Check for overtraining (too many sessions)
    // Check for undertraining (too few sessions)
    // Consider session duration trends
}
```

#### Body Temperature Assessment
```swift
func assessBodyTemperature(latestTemp: Double, baseline: Double) -> ReadinessStatus {
    // Normal range: 97.0-99.0°F (36.1-37.2°C)
    // Optimal: within 0.5°F of baseline
    // Good: within 1.0°F
    // Pay attention: >1.0°F deviation
}
```

## Data Requirements

### Available Data (Current)
- Heart rate samples from sessions
- HRV samples from sessions
- Body temperature samples
- Session frequency and duration
- Session dates and times

### Additional Data Needed
- **Sleep Data**: From HealthKit (if user grants permission)
- **Baseline Metrics**: Calculate from historical data
  - Baseline resting heart rate
  - Baseline HRV
  - Baseline body temperature
  - Normal activity patterns

## UI/UX Design Specifications

### Color Scheme
- **Optimal**: Green (`Color.green` or `Color("SuccessColor")`)
- **Good**: Blue (`Color.blue` or `Color("PlenaPrimary")`)
- **Pay Attention**: Orange (`Color.orange` or `Color("WarningColor")`)
- **Poor**: Red (`Color.red`)

### Typography
- **Score Display**: Large, bold (`.system(size: 64, weight: .bold)`)
- **Contributor Name**: `.headline` or `.title3`
- **Status Text**: `.subheadline`
- **Value Text**: `.body`

### Layout
- **Spacing**: 16-24pt between sections
- **Padding**: 16pt horizontal padding
- **Progress Bars**: Height 8-12pt, rounded corners
- **Cards**: Rounded corners (12-16pt), subtle shadows

## Testing Strategy

### Unit Tests
1. **ReadinessScoreService Tests**
   - Test each contributor calculation
   - Test overall score calculation
   - Test edge cases (no data, missing metrics)

2. **ReadinessViewModel Tests**
   - Test data loading
   - Test date navigation
   - Test comparison logic

### Integration Tests
1. Test with real session data
2. Test with missing HealthKit permissions
3. Test with insufficient data

## Future Enhancements

1. **Weekly Readiness Trends**: Chart showing readiness over time
2. **Personalized Baselines**: Learn user's normal ranges
3. **Recommendations**: Suggest optimal meditation times based on readiness
4. **Notifications**: Alert when readiness is optimal
5. **Export/Share**: Share readiness scores
6. **Watch App Integration**: Show readiness on Apple Watch

## Implementation Order

1. ✅ **Phase 1**: Models and calculation logic
2. ✅ **Phase 2**: ViewModel
3. ✅ **Phase 3**: UI Components
4. ✅ **Phase 4**: Integration
5. ✅ **Phase 5**: Testing and refinement

## Notes

- **Sleep Data**: Initially, sleep metrics may show "No data" if HealthKit sleep permissions aren't granted. This is acceptable for MVP.
- **Baselines**: For MVP, use simple statistical baselines (mean, median). Future versions can use machine learning.
- **Performance**: Calculations should be async and cached to avoid blocking UI.
- **Privacy**: All calculations happen locally. No data sent to servers.



