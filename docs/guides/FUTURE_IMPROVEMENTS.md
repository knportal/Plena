# Future Improvements

This document tracks potential enhancements and improvements across all areas of the Plena app. Each section focuses on a specific feature area or domain.

---

## 📊 HRV Insights

### ✅ Currently Implemented

#### 1. Weekly HRV Trend Insight

- **Status**: ✅ Implemented
- **Description**: Compares current week's average HRV to previous week's average HRV
- **Requirements**:
  - At least 3 sessions with HRV data in current week
  - At least 3 sessions with HRV data in previous week
  - Minimum 5% change to show insight
- **Message Format**: "HRV increased/decreased X% this week"

#### 2. Recent Sessions Improvement Insight

- **Status**: ✅ Implemented
- **Description**: Analyzes last 3 sessions for HRV improvement trend
- **Requirements**:
  - At least 3 sessions with valid HRV data (≥3 samples per session)
  - Consistent upward trend across all 3 sessions
  - Minimum 5% improvement from first to last session
- **Message Format**: "Your last 3 sessions show improved calm response"

### 🔄 Future Enhancements

#### 3. Baseline HRV Comparison

- **Priority**: High
- **Description**: Compare session HRV to user's personal baseline (morning readings)
- **Implementation Notes**:
  - Track baseline HRV from morning readings (non-meditation context)
  - Compare session HRV values to baseline
  - Show insights like "Your HRV today was 15% higher than your baseline"
- **Requirements**:
  - Need to collect baseline HRV data (morning readings)
  - Store baseline separately from session HRV
  - Calculate rolling average baseline (e.g., last 7 days)
- **Challenges**:
  - Requires additional data collection mechanism
  - Need to distinguish meditation HRV from baseline HRV
  - May need HealthKit integration for morning readings

#### 4. Time-of-Day HRV Patterns

- **Priority**: Medium
- **Description**: Identify optimal times for meditation based on HRV patterns
- **Implementation Notes**:
  - Group sessions by time of day (morning, afternoon, evening, night)
  - Calculate average HRV improvement for each time period
  - Show insights like "Your morning sessions show the best HRV response"
- **Requirements**:
  - Sufficient data across different times of day
  - At least 3 sessions per time period for statistical validity
- **UI Considerations**:
  - Could be displayed as a chart or simple insight card
  - May integrate with existing "Best Time" insight

#### 5. Session Duration Correlation

- **Priority**: Medium
- **Description**: Analyze relationship between session duration and HRV improvement
- **Implementation Notes**:
  - Group sessions by duration ranges (e.g., <10min, 10-20min, 20-30min, >30min)
  - Calculate average HRV improvement for each duration range
  - Show insights like "Your 20-30 minute sessions show the best HRV response"
- **Requirements**:
  - Sufficient data across different duration ranges
  - Need to define meaningful duration buckets
- **Use Case**:
  - Help users optimize session length for maximum HRV benefit

#### 6. Long-Term Trend Analysis (Monthly/Yearly)

- **Priority**: Medium
- **Description**: Track HRV trends over longer periods
- **Implementation Notes**:
  - Calculate monthly average HRV
  - Compare current month to previous month
  - Show yearly trends and patterns
  - Identify seasonal variations
- **Requirements**:
  - Need sufficient historical data (at least 2 months)
  - More sophisticated statistical analysis
- **UI Considerations**:
  - Could be a dedicated HRV trends chart
  - May require separate view or expandable section

#### 7. HRV Recovery Insights

- **Priority**: Low
- **Description**: Track HRV recovery patterns after stress or poor sleep
- **Implementation Notes**:
  - Integrate with sleep data (if available)
  - Identify days with low baseline HRV
  - Show how meditation helps recovery
  - Insights like "Meditation helped restore your HRV after a stressful day"
- **Requirements**:
  - Integration with sleep/stress tracking
  - Need baseline HRV data
  - Complex correlation analysis
- **Challenges**:
  - Requires additional data sources
  - Privacy considerations for health data

#### 8. Personalized HRV Goals

- **Priority**: Low
- **Description**: Set and track progress toward HRV improvement goals
- **Implementation Notes**:
  - Allow users to set HRV improvement goals
  - Track progress toward goals
  - Celebrate milestones
  - Show progress bars or visual indicators
- **Requirements**:
  - User preference storage
  - Goal tracking system
  - Notification system for milestones
- **UI Considerations**:
  - Settings page for goal configuration
  - Dashboard widget for goal progress

#### 9. HRV Coefficient of Variation (CV) Analysis

- **Priority**: Low
- **Description**: Track stability of HRV measurements
- **Implementation Notes**:
  - Calculate CV = (Standard Deviation / Mean) × 100
  - Lower CV indicates more stable autonomic function
  - Show insights about HRV stability trends
- **Requirements**:
  - Statistical calculations
  - Sufficient data points for meaningful CV
- **Use Case**:
  - Help users understand consistency of their HRV response

#### 10. Multi-Factor HRV Insights

- **Priority**: Low
- **Description**: Combine HRV with other metrics for richer insights
- **Implementation Notes**:
  - Correlate HRV with heart rate, respiratory rate
  - Identify patterns like "When your HRV increases, your heart rate decreases"
  - Show combined insights
- **Requirements**:
  - Multi-metric analysis
  - Complex correlation algorithms
- **Challenges**:
  - More complex to implement
  - May require machine learning for pattern detection

### 📊 Data Quality Improvements

#### Minimum Sample Thresholds

- **Current**: 3 HRV samples per session
- **Consideration**: May need to adjust based on session duration
- **Future**: Dynamic threshold based on session length

#### Outlier Detection

- **Status**: Not implemented
- **Description**: Filter out extreme HRV values that might skew averages
- **Implementation**: Use statistical methods (e.g., IQR, Z-score) to identify outliers
- **Priority**: Medium

#### Data Validation

- **Status**: Basic validation (sample count)
- **Future Enhancements**:
  - Validate HRV values are within physiological ranges (e.g., 10-200ms for SDNN)
  - Check for sensor errors or data corruption
  - Flag sessions with suspicious patterns

### 🎨 UI/UX Enhancements

#### Expandable Insight Cards

- **Description**: Allow users to tap insight cards for more details
- **Details to Show**:
  - Raw numbers (average HRV values)
  - Chart showing trend
  - Historical comparison
  - Educational context

#### HRV Insights Section

- **Description**: Dedicated section for HRV insights (separate from general insights)
- **Benefits**:
  - More prominent display
  - Can show multiple HRV insights together
  - Better organization

#### Visual Indicators

- **Current**: Color-coded trend arrows
- **Future**:
  - Sparkline charts for trends
  - Progress indicators
  - Animated transitions for improvements

#### 11. UI Polish + Micro-Animations

- **Priority**: Medium
- **Description**: Enhanced visual polish and smooth animations throughout the app
- **Implementation Notes**:
  - Smooth chart animations (transitions, data point animations)
  - Adaptive gradients that respond to data or time of day
  - More refined icon consistency across all screens
  - Micro-interactions for better user feedback
- **Features**:
  - **Smooth Chart Animations**:
    - Animated data point appearance
    - Smooth line drawing transitions
    - Animated axis label updates
    - Transition effects when changing time ranges
  - **Adaptive Gradients**:
    - Background gradients that adapt to session state
    - Time-of-day aware color schemes
    - Data-driven gradient intensity (e.g., brighter for better sessions)
  - **Icon Consistency**:
    - Unified icon style across iOS and Watch
    - Consistent sizing and weight
    - Semantic icon usage
    - Custom icon set where needed
- **Requirements**:
  - Animation framework/libraries
  - Design system updates
  - Icon asset creation
  - Performance optimization for animations
- **UI Considerations**:
  - Maintain 60fps performance
  - Respect reduced motion accessibility settings
  - Smooth transitions without jarring effects
  - Consistent animation timing (e.g., 0.3s standard duration)
- **Benefits**:
  - More engaging user experience
  - Professional, polished feel
  - Better visual feedback
  - Enhanced perceived quality

#### Educational Tooltips

- **Description**: Help users understand what HRV means
- **Content**:
  - What is HRV?
  - Why does it matter?
  - How to improve HRV
  - What affects HRV

---

## 📈 Dashboard & Analytics

### Future Enhancements

#### 9. Plena Score

- **Priority**: High
- **Description**: A daily composite mind-body score based on session quality & biometric trend shifts
- **Implementation Notes**:
  - Composite scoring algorithm combining multiple factors:
    - Session quality metrics (duration, consistency)
    - Biometric trend shifts (HRV improvements, heart rate reductions)
    - Zone distribution during sessions
    - Consistency of practice
  - Score range: 0-100 or similar scale
  - Daily calculation based on previous day's sessions
- **Features**:
  - Daily score display on dashboard
  - Weekly/monthly trend visualization
  - Score breakdown by contributing factors
  - Personalized score goals
- **Requirements**:
  - Scoring algorithm development
  - Multi-factor analysis system
  - Historical data tracking
  - UI components for score display
- **UI Considerations**:
  - Prominent dashboard widget
  - Score history chart
  - Breakdown view showing contributing factors
  - Goal progress indicators

#### 10. AI-Generated Daily Insight

- **Priority**: Medium
- **Description**: Non-medical coaching insights generated from biometric data patterns
- **Implementation Notes**:
  - Analyze daily biometric patterns and correlations
  - Generate personalized, contextual insights
  - Use pattern recognition to identify correlations (e.g., sleep quality → HRV, session timing → calm response)
  - Non-medical language only (coaching/wellness focus)
- **Example Insights**:
  - "Your HRV dip today likely reflects low sleep quality."
  - "Your calm response improved 30% compared to last week."
  - "Your morning sessions show stronger HRV improvement than evening ones."
  - "You've maintained optimal zone for longer periods this week."
- **Features**:
  - Daily insight generation
  - Context-aware messaging
  - Trend-based observations
  - Actionable recommendations
- **Requirements**:
  - Pattern recognition algorithms
  - Natural language generation (or templated system)
  - Data correlation analysis
  - Multi-metric analysis (HRV, HR, sleep, timing, etc.)
- **Challenges**:
  - Balancing accuracy with simplicity
  - Avoiding medical claims
  - Ensuring insights are helpful and not generic
  - Privacy considerations for data analysis
- **UI Considerations**:
  - Insight card on dashboard
  - Expandable details
  - Historical insight archive
  - Insight categories/tags

---

## 📊 Readiness Score

### Future Enhancements

#### Previous Day Activity Contributor

- **Priority**: Medium
- **Description**: Analyze previous day's meditation activity to contribute to readiness score
- **Implementation Notes**:
  - Calculate total meditation duration from previous day's sessions
  - Optimal: 15-30 minutes of meditation
  - Good: 10-15 or 30-45 minutes
  - Pay attention: <10 or >45 minutes
  - Factor into overall readiness score calculation
- **Features**:
  - Track yesterday's session duration
  - Contribute to daily readiness score
  - Provide feedback on activity levels
- **Requirements**:
  - Session data from previous day
  - Duration calculation logic
  - Status determination based on duration ranges
- **Benefits**:
  - Encourages consistent practice
  - Shows relationship between practice and readiness
  - Helps users understand optimal session duration for their readiness

#### Activity Balance Contributor

- **Priority**: Medium
- **Description**: Track consistency of meditation practice duration to contribute to readiness score
- **Implementation Notes**:
  - Calculate coefficient of variation for session durations over recent sessions
  - Lower CV = more consistent = better readiness indicator
  - Optimal: CV ≤ 0.2 (very consistent)
  - Good: CV ≤ 0.4 (moderately consistent)
  - Pay attention: CV ≤ 0.6 (somewhat inconsistent)
  - Poor: CV > 0.6 (highly inconsistent)
- **Features**:
  - Analyze duration consistency across recent sessions
  - Factor consistency into readiness score
  - Provide feedback on practice regularity
- **Requirements**:
  - Historical session duration data
  - Statistical calculation (mean, variance, standard deviation, CV)
  - Status determination based on CV thresholds
- **Benefits**:
  - Encourages regular, consistent practice
  - Shows importance of routine for readiness
  - Helps users establish consistent meditation habits

---

## 🎯 Session Tracking

### Future Enhancements

#### 4. Live Breathing Animation

- **Priority**: High
- **Description**: Optional breath guidance animation during meditation sessions with pulsing circle visualization
- **Implementation Notes**:
  - Animated pulsing circle to guide breathing rhythm
  - Multiple breathing pattern options:
    - 4-7-8 breathing (inhale 4s, hold 7s, exhale 8s)
    - Coherent breathing (5.5s inhale, 5.5s exhale)
    - Customizable breathing patterns
  - Optional feature (can be toggled on/off)
  - Visual guidance to help users establish breathing rhythm
- **Features**:
  - Smooth pulsing circle animation
  - Visual inhale/exhale phases
  - Breathing pattern selection
  - Audio cues option (optional)
  - Integration with session tracking
- **Requirements**:
  - Animation components (SwiftUI animations)
  - Breathing pattern configuration system
  - Settings for enabling/disabling
  - Timer-based animation cycles
- **UI Considerations**:
  - Prominent but non-intrusive display
  - Works alongside sensor data display
  - Can be minimized or hidden during session
  - Smooth, calming animations
- **Benefits**:
  - Very high perceived value
  - Enhances meditation experience
  - Helps establish breathing rhythm
  - May improve biometric responses

#### 8. Add Session Tags

- **Priority**: Medium
- **Description**: Allow users to label sessions with tags for better organization and trend analysis
- **Implementation Notes**:
  - Tag system for categorizing sessions
  - Pre-defined tags:
    - Time of day: Morning / Afternoon / Evening / Night
    - Mood/State: Stress / Calm / Anxious / Relaxed
    - Activity type: Breathwork / Guided / Silent / Music
  - Custom user-created tags
  - Multi-tag support (sessions can have multiple tags)
  - Tag-based filtering and trends
- **Features**:
  - Tag selection during session or after completion
  - Tag filtering in data visualization
  - Trends by tag (e.g., "Morning sessions show better HRV")
  - Tag-based insights and analytics
  - Quick tag selection UI
- **Requirements**:
  - Tag data model and storage
  - UI for tag selection/creation
  - Filtering system for data views
  - Analytics engine for tag-based trends
- **UI Considerations**:
  - Quick tag buttons in session summary
  - Tag picker with search
  - Visual tag indicators in session lists
  - Tag-based filtering in Dashboard and Data Visualization
- **Benefits**:
  - Better session organization
  - Identify patterns by context
  - More meaningful insights
  - Personalized trend analysis

---

## 🎨 Zone Classification

### ✅ Currently Implemented

#### Basic Zone Classification

- **Status**: ✅ Implemented
- **Description**: Auto-classify Heart Rate and HRV readings into color-coded stress zones (Calm, Optimal, Elevated Stress)
- **Features**:
  - Real-time zone calculation during sessions
  - Visual indicators on iOS and Watch
  - Color-coded backgrounds and borders
  - Accessibility support

### 🔄 Future Enhancements

#### 1. Personalization

- **Priority**: High
- **Description**: Personalize zone thresholds based on user's individual baseline
- **Implementation Notes**:
  - Track user's personal baseline over time
  - Use baseline for personalized zone thresholds
  - Age-adjusted HRV thresholds (SDNN naturally declines with age)
- **Requirements**:
  - Baseline tracking system
  - Historical data analysis
  - User age/preferences storage
- **Benefits**:
  - More accurate zone classification
  - Better understanding of individual stress responses
  - Age-appropriate HRV interpretation

#### 5. Personal Baseline Calibration

- **Priority**: High
- **Description**: Collect user-specific baselines over the first several sessions to personalize metrics
- **Implementation Notes**:
  - Automatic baseline collection during initial sessions (first 5-10 sessions)
  - Establish personal baselines for:
    - Normal HR range (individual resting heart rate)
    - HRV typical values (personal SDNN baseline)
    - Breathing rate baseline (typical respiratory rate)
  - Use baselines to personalize:
    - Zone classification thresholds
    - Insight generation
    - Trend analysis
  - Baseline recalibration option (periodic updates based on new data)
- **Features**:
  - Automatic baseline calculation during onboarding period
  - Baseline display in settings/profile
  - Manual baseline recalibration option
  - Baseline-based personalized insights
  - Visual indication when baseline is being established
- **Requirements**:
  - Baseline calculation algorithms
  - Data storage for personal baselines
  - Onboarding flow for baseline collection
  - Settings UI for baseline management
- **UI Considerations**:
  - Progress indicator during baseline collection
  - Baseline summary in settings
  - Clear explanation of what baselines mean
  - Option to manually trigger recalibration
- **Benefits**:
  - More accurate and personalized metrics
  - Better zone classification
  - More meaningful insights
  - User-specific context awareness

#### 2. User Preferences

- **Priority**: Medium
- **Description**: Allow users to customize zone display and thresholds
- **Implementation Notes**:
  - Settings toggle to show/hide zones
  - Custom zone threshold adjustments
  - Color scheme preferences
- **Requirements**:
  - Settings UI for zone preferences
  - Persistent storage of custom thresholds
  - UI updates based on preferences
- **UI Considerations**:
  - Add to existing Settings view
  - Advanced settings section for threshold customization

#### 3. Analytics & Insights

- **Priority**: Medium
- **Description**: Track and analyze zone patterns over time
- **Implementation Notes**:
  - Session summary includes zone distribution
  - Historical zone trends
  - Zone transition tracking
- **Features**:
  - Percentage of time spent in each zone during sessions
  - Zone trend charts over time
  - Zone transition frequency (e.g., Elevated → Optimal → Calm)
  - Best zone achievement tracking
- **Requirements**:
  - Zone data persistence
  - Chart visualization components
  - Statistical analysis for trends
- **UI Considerations**:
  - Add to session summary view
  - New analytics section or expand Dashboard
  - Visual charts showing zone distribution

#### 4. Advanced Features

- **Priority**: Low
- **Description**: Enhanced zone-based functionality
- **Implementation Notes**:
  - Zone-based insights/recommendations
  - Zone visualization in charts
  - Export zone data
- **Features**:
  - AI-powered insights based on zone patterns
  - Recommendations for improving zone distribution
  - Zone overlays on existing data visualization charts
  - CSV/JSON export of zone data for analysis
- **Requirements**:
  - Advanced analytics engine
  - Chart enhancements
  - Export functionality
- **Use Cases**:
  - Help users understand patterns
  - Enable external analysis
  - Provide actionable recommendations

---

## 📱 Apple Watch Features

### Future Enhancements

#### 6. In-App Apple Watch Compatibility Information

- **Priority**: Medium
- **Description**: Display Apple Watch model compatibility information directly in the app to help users understand which sensors are available on their specific watch model
- **Implementation Notes**:
  - Add compatibility information to Settings view
  - Show sensor availability based on detected watch model
  - Provide educational content about sensor requirements
  - Link to full compatibility guide (if hosted online)
- **Features**:
  - **Settings View Enhancement**:
    - Add info indicators (ℹ️) next to each sensor toggle
    - Show availability status: "Available" / "Requires Series X+" / "Not Available"
    - Display detected watch model (if possible)
    - Quick tooltip or info sheet explaining requirements
  - **Onboarding Screen**:
    - Detect user's Apple Watch model during first launch
    - Show which sensors are available on their watch
    - Explain what data they can collect
    - Set expectations about features
  - **Help/Info Section**:
    - Add "Device Compatibility" section in Settings
    - Show detected watch model and available sensors
    - List unavailable sensors with model requirements
    - Link to full compatibility guide
- **Requirements**:
  - Watch model detection API (if available)
  - Sensor availability checking logic
  - UI components for info indicators
  - Settings view updates
  - Onboarding flow updates
- **UI Considerations**:
  - **Settings View**:
    - Info button next to each sensor toggle
    - Modal or sheet showing compatibility details
    - Visual indicators (checkmark, warning icon, unavailable icon)
    - Clear, concise messaging
  - **Onboarding**:
    - Compatibility screen after HealthKit permissions
    - Visual list of available/unavailable sensors
    - Encouraging messaging (e.g., "You can track X, Y, Z with your watch")
  - **Help Section**:
    - Dedicated "Device Compatibility" section
    - Model detection display
    - Sensor availability matrix
    - Link to online compatibility guide
- **Benefits**:
  - Users immediately understand their watch's capabilities
  - Reduces confusion about missing sensors
  - Sets proper expectations
  - Helps users make informed upgrade decisions
  - Reduces support requests about sensor availability
- **Challenges**:
  - Watch model detection may not be directly available via API
  - May need to infer model from sensor availability
  - Keeping compatibility information up-to-date
  - Balancing information without overwhelming users
- **Example Implementation**:
  ```swift
  SensorToggleRow(
      title: "HRV (SDNN)",
      icon: "waveform.path.ecg",
      iconColor: .blue,
      isEnabled: $viewModel.hrvEnabled,
      availabilityInfo: "Requires Apple Watch Series 4 or later",
      isAvailable: watchModel.supportsHRV
  )
  ```
- **Related Documentation**:
  - See `documents/APPLE_WATCH_COMPATIBILITY.md` for complete compatibility matrix
  - See `documents/COMPATIBILITY_DOCUMENTATION_SUMMARY.md` for implementation details

#### 7. Haptic Rhythm Support

- **Priority**: High
- **Description**: Haptic feedback for breathing guidance during meditation sessions on Apple Watch
- **Implementation Notes**:
  - Taps for inhale/exhale phases
  - No screen required - users can close eyes
  - Synchronized with breathing animation (if displayed)
  - Configurable haptic patterns and intensity
  - Supports multiple breathing patterns (4-7-8, Coherent, etc.)
- **Features**:
  - Subtle tap for inhale
  - Different tap pattern for exhale
  - Optional pause/hold phase haptics
  - Haptic-only mode (no visual display needed)
  - Integration with breathing animation option
- **Requirements**:
  - Apple Watch haptic API integration
  - Timer-based haptic triggers
  - Settings for haptic intensity and patterns
  - Background haptic support (if app goes to background)
- **UI Considerations**:
  - Toggle in Watch settings
  - Intensity selection
  - Pattern selection
  - Works independently or with visual guidance
- **Benefits**:
  - Very differentiating feature
  - Hands-free breathing guidance
  - Enhanced meditation experience
  - Unique to Apple Watch platform
- **Challenges**:
  - Battery impact consideration
  - Haptic API limitations
  - Ensuring haptics are subtle and non-disruptive

---

## 🔧 Technical Improvements

### HealthKit Integration

#### 7. Expand HealthKit Metrics

- **Priority**: Medium
- **Description**: Optional additional HealthKit metrics to strengthen long-term insights and enhance Data tab utility
- **Implementation Notes**:
  - Add support for additional HRV metrics:
    - **RMSSD** (Root Mean Square of Successive Differences) - another time-domain HRV metric
    - **Sleep-based HRV** - HRV measurements during sleep periods
  - Add recovery metrics:
    - **HR Recovery** - Heart rate recovery after exercise/activity
  - Enhanced VO2 Max tracking:
    - **VO2 Max trend** - Track VO2 Max changes over time
    - Correlation with meditation sessions
- **Features**:
  - Optional metric selection (user can enable/disable)
  - RMSSD calculation and display
  - Sleep HRV integration and comparison
  - HR Recovery tracking and insights
  - VO2 Max trend visualization
  - Cross-metric correlation analysis
- **Requirements**:
  - HealthKit authorization for new metric types
  - Data models for additional metrics
  - Query logic for new HealthKit types
  - Storage for new metric data
  - UI updates for metric display
- **Benefits**:
  - More comprehensive biometric picture
  - Stronger long-term insights
  - Better data visualization utility
  - Richer trend analysis
  - Cross-metric pattern identification
- **UI Considerations**:
  - Settings toggle for each new metric
  - Metric selection in Data Visualization
  - New chart types for trends
  - Correlation views showing relationships

### Caching & Performance

- **Status**: Calculations run on-demand
- **Future**:
  - Cache weekly calculations (recalculate daily)
  - Background calculation for insights
  - Optimize database queries

### Statistical Robustness

- **Current**: Simple averages and percentage changes
- **Future**:
  - Confidence intervals
  - Statistical significance testing
  - Trend smoothing (moving averages)
  - Linear regression for trend detection

### Error Handling

- **Status**: Basic error handling
- **Future**:
  - Graceful degradation when data is insufficient
  - Clear error messages
  - Fallback insights when primary insights unavailable

---

## 🧪 Testing & Validation

### Unit Tests

- **Status**: Not implemented
- **Priority**: High
- **Test Cases**:
  - Weekly trend calculation with various data scenarios
  - Recent sessions improvement detection
  - Edge cases (insufficient data, outliers, etc.)

### User Testing

- **Status**: Not conducted
- **Focus Areas**:
  - Insight clarity and usefulness
  - Message wording
  - Visual design
  - User understanding of HRV

---

## 📚 Documentation

### User Guide

- **Status**: Not created
- **Content**:
  - How to interpret HRV insights
  - What affects HRV
  - How to improve HRV through meditation

### Developer Documentation

- **Status**: Partial (code comments)
- **Future**:
  - Architecture documentation
  - Algorithm explanations
  - Data flow diagrams

---

## 🎯 Success Metrics

### Key Performance Indicators

- User engagement with insights
- User understanding (survey/feedback)
- Feature usage statistics
- Impact on meditation consistency

### Analytics to Track

- How often insights are shown
- Which insights are most common
- User interaction with insights
- Correlation between insights and app usage

---

## 📝 Notes

### Research References

- Elite HRV best practices
- HeartMath research on HRV and meditation
- Academic papers on HRV trend analysis

### Design Decisions

- 5% threshold chosen based on research indicating meaningful change
- 3 sessions minimum for statistical validity
- Weekly comparison provides good balance of recency and stability

### Open Questions

- Should insights be always visible or toggleable?
- How detailed should insights be?
- Should we show negative trends or only positive?
- How to handle users with irregular meditation patterns?

---

## 🔄 Version History

- **v1.0** (Current): Basic weekly trend and recent sessions insights
- **Future**: Track version updates as features are added

---

_Last Updated: December 6, 2025 (Added item 6: In-App Apple Watch Compatibility Information)_
_Maintained by: Development Team_
