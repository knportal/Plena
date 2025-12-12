# Plena App Overview

## What is Plena?

**Plena** is a meditation tracking application for iPhone and Apple Watch that monitors your biometric data in real time during meditation sessions. By tracking heart rate, heart rate variability (HRV), respiratory rate, and other vital signs, Plena helps you understand how your body responds to meditation and track your progress over time.

---

## 🔺 The Meaning of the Plena Triangle

The three connected points inside the Plena icon represent the three core rhythms of human calm:

**Mind — Breath — Body**

Or scientifically:

**Heart Rate → HRV → Respiration**

These three systems form a loop:

- **Heart rate** reflects moment-to-moment activity
- **HRV** shows adaptability and stress balance
- **Breath** regulates the entire system

When they work in harmony, the triangle becomes balanced — stable, coherent, and calm. That's exactly what Plena measures in real time.

---

## Key Features Overview

### Real-Time Biometric Tracking

Plena tracks multiple biometric signals during your meditation sessions:

- **Heart Rate (HR)** - Monitors your heart rate in beats per minute (BPM)
- **Heart Rate Variability (HRV/SDNN)** - Measures the variation between heartbeats, indicating your body's ability to adapt to stress
- **Respiratory Rate** - Tracks your breathing rate per minute
- **Body Temperature** - Monitors body temperature changes during sessions
- **VO₂ Max** - Tracks your maximum oxygen consumption (periodic readings)

All data is collected in real time using Apple's HealthKit framework, ensuring accurate and secure health data tracking.

### Stress Zone Classification

Plena automatically classifies your biometric readings into color-coded stress zones:

- **🔵 Calm Zone** (Blue) - Indicates a relaxed, calm state
- **🟢 Optimal Zone** (Green) - Your body is in balance, functioning well
- **🟠 Elevated Stress Zone** (Orange) - Indicates elevated stress levels

These zones provide instant visual feedback to help you understand your current state and track improvements over time.

### Comprehensive Dashboard

View your meditation progress at a glance:

- **Session Statistics** - Total sessions, total meditation time, current streak, average duration
- **Trend Analysis** - See how your meditation practice evolves over time
- **Session Frequency Charts** - Visualize your consistency with interactive bar charts
- **Duration Trends** - Track session length patterns with line charts
- **HRV Insights** - Get personalized insights about your heart rate variability trends
- **Period Comparisons** - Compare current period to previous (e.g., this week vs last week)
- **Best Time Analysis** - Discover your optimal meditation times
- **Longest Session Tracking** - Celebrate your personal records

The dashboard supports multiple time ranges: Day, Week, Month, and Year views.

### Interactive Data Visualization

Explore your historical meditation data with beautiful, interactive graphs:

- **Time-Based Views** - Day, Week, Month, and Year perspectives
- **Sensor-Specific Charts** - Individual graphs for each biometric measurement
- **Multiple View Modes** - Switch between Consistency view (zone distribution) and Trend view (value over time)
- **Range Indicators** - See how your values compare to normal ranges
- **Trend Statistics** - Get insights about trends (improving, declining, stable)
- **Zone Distribution** - See percentage of time spent in each stress zone
- **Metric Selection** - Choose which sensors to visualize (Heart Rate, HRV, Respiratory Rate, Temperature, VO₂ Max)

### Apple Watch Integration

Start and track meditation sessions directly from your Apple Watch:

- **Independent Operation** - Works independently from your iPhone
- **Real-Time Display** - See sensor readings on your wrist
- **Zone Indicators** - Visual stress zone feedback on the Watch face
- **Easy Controls** - Start/stop sessions with a simple tap
- **3-2-1 Countdown** - Gentle preparation countdown before sessions begin

### Session Management

- **Session Summaries** - Review detailed statistics after each session
- **State of Mind Logging** - Record how you felt during meditation
- **Automatic Saving** - All sessions are automatically saved to your device
- **Historical Import** - Import existing HealthKit data from past sessions

### Readiness Score

Get a holistic view of your recovery and readiness with Plena's comprehensive Readiness Score:

- **Daily Score Calculation** - Receive a readiness score (0-100) for each day
- **Multiple Contributors** - Score based on:
  - **Resting Heart Rate** - Your baseline heart rate during rest
  - **HRV Balance** - Heart rate variability balance and trends
  - **Body Temperature** - Temperature patterns and deviations
  - **Recovery Index** - Recovery from previous sessions
  - **Sleep Status** - Sleep duration and quality (from HealthKit)
  - **Sleep Balance** - Sleep consistency and patterns
  - **Sleep Regularity** - Sleep schedule consistency
- **Detailed Breakdowns** - Tap any contributor to see detailed analysis
- **Historical Comparison** - Compare today's score to yesterday
- **Visual Indicators** - Color-coded scores (Excellent, Good, Fair, Poor)
- **Actionable Insights** - Understand what factors are affecting your readiness

### Smart Insights

Plena analyzes your data to provide meaningful insights:

- **Weekly HRV Trends** - Compare current week to previous week
- **Improvement Tracking** - Identify positive trends in your meditation practice
- **Pattern Recognition** - Discover what times or durations work best for you
- **Readiness Insights** - Understand how meditation affects your overall readiness

---

## Supported Platforms

- **iOS 17.0+** - Full-featured iPhone app
- **watchOS 10.0+** - Companion Apple Watch app

**Note:** Both apps require physical devices. HealthKit features do not work in simulators.

### Apple Watch Model Compatibility

Different Apple Watch models support different sensors. Plena adapts to your watch's capabilities:

- **Heart Rate**: Available on all Apple Watch models (Series 1+)
- **HRV (SDNN)**: Requires Series 4 or later
- **Respiratory Rate**: Requires Series 6 or later
- **Temperature**: Requires Series 8/Ultra or later
- **VO₂ Max**: Available on Series 3+ (accuracy varies)

**For complete compatibility information:**
See the [Apple Watch Compatibility Guide](APPLE_WATCH_COMPATIBILITY.md) for detailed sensor availability by model.

---

## Who Should Use Plena?

Plena is ideal for:

- **Meditation Practitioners** - Anyone who practices meditation and wants to understand their body's response
- **Wellness Enthusiasts** - People interested in tracking their stress levels and recovery
- **Biohackers** - Individuals who want data-driven insights into their meditation practice
- **Health-Conscious Individuals** - Anyone looking to improve their mental and physical wellbeing through meditation

---

## Benefits of Using Plena

### 📊 Data-Driven Meditation

Move beyond subjective feelings and gain objective insights into how meditation affects your body.

### 🎯 Track Progress

See real improvements over time with visual charts and statistics that show your meditation journey.

### 🧘 Deeper Understanding

Learn how different meditation sessions, durations, and times of day affect your stress levels and recovery.

### ⚡ Real-Time Feedback

Get immediate visual feedback during sessions with stress zone indicators, helping you understand your current state.

### 🔄 Consistency Tracking

Build better habits with streak tracking and session frequency analysis.

### 💪 Holistic View

See how heart rate, HRV, and breathing work together as an interconnected system (just like the triangle in our icon).

---

## Technical Requirements

### Device Requirements

- iPhone running iOS 17.0 or later
- Apple Watch (Series 4 or later) running watchOS 10.0 or later (optional but recommended)
- HealthKit-capable device (all modern iPhones and Apple Watches)

### Permissions Required

- **HealthKit Read Access** - To read heart rate, HRV, respiratory rate, temperature, and VO₂ Max data
- **HealthKit Write Access** - To save meditation session data back to HealthKit

All permissions are requested when you first use the app, and you can change them anytime in Settings → Privacy & Security → Health.

---

## Privacy & Data Security

- All health data is stored locally on your device using CoreData
- Optional CloudKit sync keeps data synchronized between your iPhone and Apple Watch (your iCloud account)
- HealthKit data remains in Apple's secure HealthKit framework
- Plena respects your privacy - no data is shared with third parties
- You control all HealthKit permissions
- See our [Privacy Policy](PRIVACY_POLICY.md) for complete details

---

## Getting Started

1. **Download** Plena from the App Store
2. **Grant Permissions** - Allow HealthKit access when prompted
3. **Start Your First Session** - Tap "Start Session" and begin meditating
4. **Review Your Data** - Check the Dashboard and Data tabs to see your progress

For detailed setup instructions, see the [User Guide](USER_GUIDE.md).

---

## Summary

Plena transforms meditation from a subjective practice into a data-driven journey of self-discovery. By tracking the three core rhythms — heart rate, HRV, and breath — Plena helps you understand how meditation affects your body and mind, track your progress, and develop a more consistent, effective meditation practice.

The triangle in our icon isn't just a design choice — it represents the interconnected balance between mind, body, and breath that Plena helps you achieve.

---

_For troubleshooting help, see [Troubleshooting Guide](TROUBLESHOOTING.md)._
_For setup instructions, see [User Guide](USER_GUIDE.md)._
