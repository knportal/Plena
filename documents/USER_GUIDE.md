# Plena User Guide

Complete setup and usage instructions for the Plena mindfulness tracking app.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Initial Setup](#initial-setup)
3. [Starting Your First Session](#starting-your-first-session)
4. [Understanding Real-Time Data](#understanding-real-time-data)
5. [Using the Dashboard](#using-the-dashboard)
6. [Data Visualization](#data-visualization)
7. [Session Summary](#session-summary)
8. [Tips & Best Practices](#tips--best-practices)

---

## Getting Started

### System Requirements

- **iPhone**: iOS 17.0 or later
- **Apple Watch** (optional): watchOS 10.0 or later (Series 4 or newer)
- Physical device required (HealthKit doesn't work in simulators)

### Download & Installation

1. Download Plena from the App Store on your iPhone
2. The app will automatically install
3. The Apple Watch companion app will automatically install on your paired Watch (if available)

### First Launch Walkthrough

When you first open Plena, you'll see the main mindfulness screen with a "Start Session" button. Before you begin, you'll need to set up HealthKit permissions.

---

## Initial Setup

### HealthKit Permissions Setup

#### Why Permissions Are Needed

Plena uses Apple's HealthKit framework to read and write health data. HealthKit is a secure, privacy-focused system that requires your explicit permission for each type of health data.

Plena needs permission to:

- **Read** your heart rate, HRV, respiratory rate, temperature, and VO₂ Max data
- **Write** mindfulness session data back to HealthKit

#### Step-by-Step Permission Grant

1. When you first tap "Start Session," you'll see a permission request dialog
2. Tap **"Allow"** or **"Turn All Categories On"**
3. If you see individual permission requests, grant access for:

   - ✅ Heart Rate (Read)
   - ✅ Heart Rate Variability (Read)
   - ✅ Respiratory Rate (Read)
   - ✅ Body Temperature (Read)
   - ✅ VO₂ Max (Read)
   - ✅ Mindfulness (Write)

4. All permissions should be turned ON (green)

#### Troubleshooting Permission Issues

**If you accidentally denied permissions:**

1. Open **Settings** on your iPhone
2. Go to **Privacy & Security** → **Health**
3. Tap **Plena**
4. Turn ON all the data types listed above

**If permissions aren't working:**

- Make sure you're on a physical device (not simulator)
- Ensure iOS 17.0+ is installed
- Try restarting your iPhone
- Reinstall the app if issues persist

For more help, see the [Troubleshooting Guide](TROUBLESHOOTING.md).

---

### Apple Watch Setup

#### Installing the Watch App

1. The Watch app should automatically install when you pair your Watch with your iPhone
2. If it doesn't appear:
   - Open the **Watch** app on your iPhone
   - Scroll to **Plena** under "Available Apps"
   - Tap **Install**

#### Verifying Watch Connection

1. On your Watch, look for the Plena app icon (triangle with connected points)
2. Tap to open it
3. You should see the mindfulness interface

#### Watch App Permissions

The Watch app uses the same HealthKit permissions as your iPhone. Once you've granted permissions on your iPhone, they automatically apply to the Watch app.

**To verify Watch permissions:**

1. Open **Watch** app on iPhone
2. Go to **Privacy & Security** → **Health**
3. Ensure Plena has the necessary permissions

#### Understanding Your Watch's Capabilities

Different Apple Watch models support different sensors. Knowing what your watch can do helps you understand what data Plena can collect:

- **Heart Rate**: Available on all Apple Watch models (Series 1+)
- **HRV (SDNN)**: Requires Apple Watch Series 4 or later
- **Respiratory Rate**: Requires Apple Watch Series 6 or later
- **Temperature**: Requires Apple Watch Series 8/Ultra or later
- **VO₂ Max**: Available on Series 3+ (accuracy varies by model)

**For detailed information about your specific watch model:**
See the [Apple Watch Compatibility Guide](APPLE_WATCH_COMPATIBILITY.md) for a complete breakdown of sensor availability by model.

---

## Starting Your First Session

### From iPhone

1. Open the **Plena** app on your iPhone
2. You'll see the main mindfulness screen with a "Start Session" button
3. Tap **"Start Session"**
4. A **3-2-1 countdown** will appear — take this time to get comfortable
5. After the countdown, tracking begins automatically
6. The iPhone displays a timer showing elapsed session time
7. Your Apple Watch (if paired) displays real-time sensor readings and streams data to iPhone

**To stop the session:**

- Tap the **"Stop Session"** button on either device
- Review your session summary

### From Apple Watch

1. Open the **Plena** app on your Apple Watch
2. Tap the screen or Digital Crown to start
3. A **3-2-1 countdown** begins
4. After countdown, sensor readings appear and data streams live to your iPhone
5. Swipe vertically to see different sensors (Heart Rate, HRV, Respiratory Rate)
6. Each sensor shows:
   - Current value
   - Unit (BPM, ms, /min)
   - Stress zone indicator (if applicable)

**To stop the session:**

- Tap the **"Stop"** button on the Watch
- Session data automatically syncs to your iPhone

### During the Session

- **iPhone Display**: Shows session timer (elapsed time in MM:SS format)
- **Watch Display**: Shows real-time sensor data (Heart Rate, HRV, Respiratory Rate)
- **Live Data Sync**: Watch streams sensor data directly to iPhone in real-time
- **Stay Still**: For best sensor readings, try to remain relatively still
- **Wear Your Watch Properly**: Ensure your Apple Watch is snug but comfortable on your wrist
- **Focus on Breathing**: The sensors will track your body's response naturally
- **Monitor Zones**: Watch the color-coded zone indicators on your Watch for real-time feedback

---

## Understanding Real-Time Data

**Important:** During meditation sessions, sensor data is displayed on your Apple Watch. The Watch streams this data in real-time to your iPhone, where you can view the complete summary after your session ends.

### Heart Rate

**What it shows:** Your current heart rate in beats per minute (BPM)

**Normal range:** 60-100 BPM (resting)

**During mindfulness:** Heart rate typically decreases as you relax

**Zone Classification:**

- 🔵 **Calm**: < 60 BPM (or below personal baseline -10%)
- 🟢 **Optimal**: 60-100 BPM (or within ±10% of baseline)
- 🟠 **Elevated Stress**: > 100 BPM (or above baseline +15%)

### HRV (Heart Rate Variability / SDNN)

**What it shows:** Variation between heartbeats in milliseconds

**Why it matters:** Higher HRV indicates better stress adaptability and recovery

**Normal range:** 50-100 ms (varies by age and fitness)

**During mindfulness:** HRV typically increases as you relax

**Zone Classification:**

- 🟠 **Elevated Stress**: < 50 ms
- 🟢 **Optimal**: 50-100 ms
- 🔵 **Calm**: > 100 ms

**Understanding HRV:**

- Higher is generally better (shows adaptability)
- HRV naturally decreases with age
- Regular mindfulness can improve HRV over time

### Respiratory Rate

**What it shows:** Number of breaths per minute

**Normal range:** 12-20 breaths per minute

**During mindfulness:** Breathing typically slows and becomes more regular

**Why it matters:** Slower, deeper breathing activates the parasympathetic nervous system (rest and digest)

**How it's measured:** On Apple Watch (Series 6+), respiratory rate is algorithmically derived from accelerometer, motion sensor, and photoplethysmography (PPG) data rather than directly counting breaths. This provides an estimation of breathing frequency that may differ from direct clinical measurements. Accuracy can be affected by movement, device positioning, and signal quality.

### Other Sensors

**Body Temperature:**

- Monitors temperature changes during sessions
- Small decreases are normal during deep relaxation

**VO₂ Max:**

- Maximum oxygen consumption
- Typically measured periodically (not continuously)
- Provides insights into overall fitness level

---

## Understanding Stress Zones

### What Each Zone Means

**🔵 Calm Zone (Blue)**

- Your body is in a relaxed, calm state
- Stress response is low
- Good for recovery and restoration

**🟢 Optimal Zone (Green)**

- Your body is in balance
- Not too stressed, not too relaxed
- Ideal functioning state

**🟠 Elevated Stress Zone (Orange)**

- Stress response is elevated
- Body may be reacting to stress or activity
- Normal during transition periods

### How Zones Are Calculated

Zones are calculated automatically based on:

- Your current sensor readings
- Established physiological ranges
- (Future: Your personal baseline)

### Zone Indicators

**On iPhone:**

- Zone badge appears below the sensor value
- Colored background and border on sensor cards
- Text labels: "Calm", "Optimal", or "Elevated Stress"

**On Apple Watch:**

- Compact zone badge next to values
- Colored background on sensor displays

**Understanding Zones:**

- Zones update in real time as your body state changes
- It's normal to see zone transitions during a session
- Moving from Elevated → Optimal → Calm is a positive trend

---

## Using the Dashboard

The Dashboard tab shows your mindfulness statistics and progress.

### Viewing Statistics

**Stat Cards:**

- **Sessions** - Total number of mindfulness sessions
- **Total Time** - Cumulative mindfulness time (with average duration)
- **Streak** - Current consecutive days with at least one session
- **Avg Duration** - Average session length

**Time Range Selector:**

- Tap the segmented control at the top: **Day**, **Week**, **Month**, **Year**
- Statistics update based on selected time range

### Understanding Charts

**Session Frequency Chart:**

- Bar chart showing sessions per day/week/month
- Helps you see consistency patterns
- Green bars indicate days with sessions

**Duration Trend Chart:**

- Line chart showing average session duration over time
- Trends upward? Your sessions are getting longer
- Trends downward? Consider re-establishing your routine

### HRV Insights

The Dashboard may show personalized insights such as:

- **"HRV increased X% this week"** - Your heart rate variability improved
- **"Your last 3 sessions show improved calm response"** - Positive trend detected

These insights appear when you have sufficient data (typically 3+ sessions with HRV data).

---

## Data Visualization

The Data tab lets you explore your historical mindfulness data in detail.

### Viewing Historical Data

1. Open the **Data** tab (chart icon)
2. Select a **time range**: Day, Week, Month, or Year
3. Scroll to see different sensors

### Understanding Graphs

**Graph Features:**

- **Interactive Charts** - Tap and drag to see specific values
- **Time Axis** - Horizontal axis shows time
- **Value Axis** - Vertical axis shows sensor readings
- **Data Points** - Each point represents a measurement during a session

**Sensor Selection:**

- Scroll through different sensor graphs
- Each sensor has its own chart
- Graphs are color-coded (Heart Rate = red, HRV = blue, etc.)

### Time Range Views

**Day View:**

- Shows all sessions from today
- Detailed view of today's data

**Week View:**

- Last 7 days of data
- Good for seeing weekly patterns

**Month View:**

- Last 30 days
- Shows broader trends

**Year View:**

- Last year of data
- Long-term progress visualization

### Range Indicators

Some sensors show range indicators:

- **Above Normal** - Value is higher than typical
- **Normal** - Value is within expected range
- **Below Normal** - Value is lower than typical

These help you understand if readings are typical or noteworthy.

---

## Session Summary

After you stop a mindfulness session, you'll see a summary screen.

### Reviewing Session Data

**Summary Information:**

- **Duration** - How long your session lasted
- **Average Heart Rate** - Mean heart rate during session
- **Average HRV** - Mean HRV during session
- **Average Respiratory Rate** - Mean breathing rate
- **Zone Distribution** - Percentage of time in each zone

**Review Options:**

- Scroll to see all statistics
- Tap "Done" when finished reviewing
- Session is automatically saved

### State of Mind Logging

After reviewing your session, you can optionally log your state of mind:

- How did you feel during the session?
- Select from predefined options or add notes
- This helps track subjective experience alongside objective data

---

## Tips & Best Practices

### Getting Accurate Readings

**For Best Heart Rate Accuracy:**

- Keep your Apple Watch snug but comfortable
- Ensure the Watch sensor is clean
- Stay relatively still during measurements
- Avoid excessive movement

**For Best HRV Accuracy:**

- HRV readings require at least 3 samples per session
- Longer sessions (10+ minutes) provide more reliable HRV data
- Try to remain in a consistent position

**For Best Respiratory Rate:**

- Allow natural breathing (don't force it)
- The sensor uses algorithmic estimation from multiple data sources
- Keep your Apple Watch snug on your wrist for better signal quality
- Minimize excessive movement for more accurate readings
- Relax and let your body breathe naturally
- Note: This is a derived measurement, not a direct breath count

### Optimal Session Duration

- **Minimum**: 5 minutes (for basic tracking)
- **Recommended**: 10-20 minutes (for meaningful HRV data)
- **Ideal**: 20-30 minutes (for comprehensive insights)

**Tip:** Start with shorter sessions and gradually increase duration as you build your practice.

### When to Use Watch vs iPhone

**Use Apple Watch when:**

- You want to practice mindfulness without your phone nearby
- You prefer minimal distractions
- You want to see real-time sensor data during your session
- You want haptic feedback (future feature)
- You're doing active mindfulness (walking, etc.)

**Use iPhone when:**

- You want to start a session and let your Watch handle the measurements
- You prefer to review data after the session completes
- You're doing guided mindfulness with audio
- You want to review historical data and trends

**Pro Tip:** Start sessions from either device — the Watch collects sensor data and streams it live to your iPhone. After the session, view the complete summary on your iPhone with all the data collected by your Watch.

### Building Consistency

- **Set a Schedule** - Practice mindfulness at the same time each day
- **Track Your Streak** - Watch your Dashboard streak grow
- **Review Weekly** - Check your Week view to see progress
- **Be Patient** - HRV improvements take time (weeks to months)

### Understanding Your Data

**Don't Obsess Over Single Readings:**

- One session doesn't define your practice
- Look at trends over days and weeks
- Focus on overall patterns, not individual numbers

**Watch for Patterns:**

- Do morning sessions show different HRV than evening?
- Do longer sessions lead to better zone distribution?
- Does consistency improve your metrics?

**Use Insights Wisely:**

- HRV insights appear when you have sufficient data
- Trust the trends, not individual sessions
- Combine objective data with subjective feelings

---

## Quick Reference

### Starting a Session

1. Open Plena app
2. Tap "Start Session"
3. Wait for 3-2-1 countdown
4. Practice mindfulness and monitor readings
5. Tap "Stop Session" when done

### Checking Permissions

1. Settings → Privacy & Security → Health
2. Tap Plena
3. Ensure all categories are ON

### Viewing Dashboard

1. Open Plena app
2. Tap "Dashboard" tab
3. Select time range (Day/Week/Month/Year)
4. Review statistics and charts

### Viewing Historical Data

1. Open Plena app
2. Tap "Data" tab
3. Select time range
4. Scroll through sensor graphs

---

## Need Help?

If you encounter issues:

1. Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
2. Verify HealthKit permissions are enabled
3. Ensure you're using a physical device (not simulator)
4. Try restarting your device

For technical support, see the [App Overview](APP_OVERVIEW.md) for contact information.

---

_Happy practicing! 🧘‍♀️✨_

---

**Last Updated:** January 1, 2026


