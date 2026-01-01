# Apple Watch Model Compatibility & Sensor Capabilities

This document outlines which Plena features are available on different Apple Watch models. Understanding your watch's capabilities helps you know what data you can collect and display during mindfulness sessions.

---

## Quick Reference Table

| Sensor/Feature       | Series 1-3 | Series 4-5 | Series 6-7 | Series 8/Ultra | Series 9+      |
| -------------------- | ---------- | ---------- | ---------- | -------------- | -------------- |
| **Heart Rate**       | ✅ Yes     | ✅ Yes     | ✅ Yes     | ✅ Yes         | ✅ Yes         |
| **HRV (SDNN)**       | ❌ No      | ✅ Yes     | ✅ Yes     | ✅ Yes         | ✅ Yes         |
| **Respiratory Rate** | ❌ No      | ❌ No      | ✅ Yes     | ✅ Yes         | ✅ Yes         |
| **VO₂ Max**          | ⚠️ Limited | ✅ Yes     | ✅ Yes     | ✅ Yes         | ✅ Yes         |
| **Temperature**      | ❌ No      | ❌ No      | ❌ No      | ✅ Yes (Wrist) | ✅ Yes (Wrist) |

**Legend:**

- ✅ **Yes** - Fully supported with accurate readings
- ⚠️ **Limited** - Available but may be less accurate or require specific conditions
- ❌ **No** - Not supported on this model

---

## Detailed Sensor Capabilities by Model

### Heart Rate Monitoring

**Available on:** All Apple Watch models (Series 1 and later)

**What it measures:**

- Beats per minute (BPM)
- Real-time heart rate during mindfulness sessions
- Resting heart rate trends

**How it works:**

- Uses green LED lights and photodiodes to detect blood flow
- Measures heart rate every few seconds during active sessions
- Works best when watch is snug on your wrist

**Plena Usage:**

- Displays real-time BPM during mindfulness sessions
- Tracks average heart rate per session
- Shows heart rate zones (Calm, Optimal, Elevated Stress)

---

### HRV (Heart Rate Variability / SDNN)

**Available on:** Apple Watch Series 4 and later

**What it measures:**

- Variation in time between heartbeats (in milliseconds)
- Indicates your body's ability to adapt to stress
- Higher HRV generally indicates better recovery and stress management

**How it works:**

- Uses the same heart rate sensor technology
- Calculates SDNN (Standard Deviation of Normal-to-Normal intervals)
- Requires multiple heart rate samples to calculate accurately

**Plena Usage:**

- Displays HRV in milliseconds (ms)
- Shows HRV zones (Elevated Stress, Optimal, Calm)
- Tracks HRV trends over time
- Provides insights about mindfulness effectiveness

**Why Series 4+?**

- Series 4 introduced improved heart rate sensor technology
- More accurate R-R interval detection required for HRV calculation
- Earlier models don't have sufficient sensor precision

**Note:** HRV readings require at least 3 samples per session. Longer mindfulness sessions (10+ minutes) provide more reliable HRV data.

---

### Respiratory Rate

**Available on:** Apple Watch Series 6 and later

**What it measures:**

- Number of breaths per minute
- Breathing patterns during mindfulness sessions
- Changes in breathing rate as you relax

**How it works:**

- Uses motion sensors (accelerometer and gyroscope)
- Detects subtle chest movements associated with breathing
- Works best when you're relatively still

**Plena Usage:**

- Displays breathing rate in breaths per minute (/min)
- Tracks respiratory rate during mindfulness sessions
- Shows how breathing slows as you relax

**Why Series 6+?**

- Series 6 introduced enhanced motion sensors
- Improved algorithms for detecting breathing patterns
- Earlier models lack the necessary sensor precision

**Note:** Respiratory rate may take longer to appear than heart rate. Stay relatively still for best results.

---

### VO₂ Max

**Available on:** Apple Watch Series 3 and later (with limitations)

**What it measures:**

- Maximum oxygen consumption during exercise
- Overall cardiovascular fitness level
- Typically measured during workouts, not continuously

**How it works:**

- Calculated from heart rate data during outdoor walks/runs
- Uses algorithms based on age, gender, and activity level
- Not measured in real-time during mindfulness sessions

**Plena Usage:**

- Displays latest VO₂ Max reading from HealthKit
- Shows periodic updates (not continuous)
- Provides context about overall fitness level

**Model Differences:**

- **Series 3-5:** Basic VO₂ Max estimation (less accurate)
- **Series 6+:** Improved accuracy with better sensors
- **Series 8+:** Most accurate with enhanced heart rate sensors

**Note:** VO₂ Max is typically measured during workouts, not mindfulness. Plena displays your most recent VO₂ Max reading from HealthKit.

---

### Temperature Monitoring

**Available on:** Apple Watch Series 8, Ultra, and later

**What it measures:**

- Wrist temperature (Series 8/Ultra)
- Body temperature trends
- Temperature changes during mindfulness sessions

**How it works:**

- Uses a temperature sensor on the back of the watch
- Measures wrist temperature while you sleep
- Tracks temperature trends over time

**Plena Usage:**

- Displays temperature in Celsius or Fahrenheit
- Shows temperature changes during mindfulness sessions
- Tracks temperature trends over sessions

**Model Differences:**

- **Series 8/Ultra:** Wrist temperature sensor (most accurate)
- **Series 9+:** Enhanced temperature sensing
- **Series 6-7:** No temperature sensor (temperature data unavailable)
- **Series 4-5:** No temperature sensor
- **Series 1-3:** No temperature sensor

**Note:** Temperature readings are most accurate when taken during sleep. during mindfulness sessions, temperature changes may be subtle.

---

## Model-Specific Recommendations

### Apple Watch Series 1-3

**Available Sensors:**

- ✅ Heart Rate
- ⚠️ VO₂ Max (limited accuracy)

**Recommendations:**

- Focus on heart rate tracking during mindfulness sessions
- Heart rate zones will still provide valuable feedback
- Consider upgrading to Series 4+ for HRV tracking

**What You'll See in Plena:**

- Heart rate readings and zones
- Basic mindfulness session tracking
- Limited insights (no HRV, respiratory rate, or temperature)

---

### Apple Watch Series 4-5

**Available Sensors:**

- ✅ Heart Rate
- ✅ HRV (SDNN)
- ⚠️ VO₂ Max

**Recommendations:**

- Excellent for mindfulness tracking with HRV
- HRV provides deeper insights into stress response
- Respiratory rate not available (requires Series 6+)

**What You'll See in Plena:**

- Heart rate and HRV tracking
- Stress zone classification
- HRV-based insights
- No respiratory rate or temperature data

---

### Apple Watch Series 6-7

**Available Sensors:**

- ✅ Heart Rate
- ✅ HRV (SDNN)
- ✅ Respiratory Rate
- ✅ VO₂ Max
- ❌ Temperature

**Recommendations:**

- Comprehensive mindfulness tracking
- All core sensors available (except temperature)
- Best balance of features and affordability

**What You'll See in Plena:**

- Heart rate, HRV, and respiratory rate tracking
- Complete stress zone analysis
- Comprehensive mindfulness insights
- No temperature data

---

### Apple Watch Series 8 / Ultra

**Available Sensors:**

- ✅ Heart Rate
- ✅ HRV (SDNN)
- ✅ Respiratory Rate
- ✅ VO₂ Max
- ✅ Temperature (Wrist)

**Recommendations:**

- Full sensor suite for complete mindfulness tracking
- Temperature adds another dimension to stress tracking
- Best overall experience

**What You'll See in Plena:**

- All sensors available
- Complete biometric tracking
- Temperature trends during mindfulness sessions
- Most comprehensive insights

---

### Apple Watch Series 9 and Later

**Available Sensors:**

- ✅ Heart Rate
- ✅ HRV (SDNN)
- ✅ Respiratory Rate
- ✅ VO₂ Max
- ✅ Temperature (Enhanced)

**Recommendations:**

- Latest sensor technology
- Most accurate readings
- Enhanced temperature sensing
- Best possible mindfulness tracking experience

**What You'll See in Plena:**

- All sensors with enhanced accuracy
- Most comprehensive data collection
- Advanced insights and trends

---

## Understanding "Sensor Unavailable" Messages

If you see "Sensor Unavailable" in Plena, it could mean:

1. **Your Watch Model Doesn't Support It:**

   - Check the compatibility table above
   - Some sensors require newer watch models

2. **Watch Not Connected:**

   - Ensure Apple Watch is paired and connected to iPhone
   - Check Bluetooth connection

3. **Insufficient Data:**

   - Some sensors (like HRV) need multiple samples
   - Try a longer mindfulness session (10+ minutes)

4. **Watch Not Worn Properly:**

   - Ensure watch is snug but comfortable
   - Clean the sensor on the back of the watch
   - Keep watch in contact with your skin

5. **Permissions Not Granted:**
   - Check HealthKit permissions in Settings
   - Ensure all required permissions are enabled

---

## Tips for Best Results

### For All Watch Models:

1. **Wear Your Watch Properly:**

   - Snug but comfortable fit
   - Sensor should contact your skin
   - Clean sensor regularly

2. **Stay Relatively Still:**

   - Movement affects sensor accuracy
   - Rest your arm if possible
   - Avoid excessive fidgeting

3. **Longer Sessions = Better Data:**
   - Minimum 5 minutes for basic tracking
   - 10+ minutes for reliable HRV
   - 20+ minutes for comprehensive insights

### For HRV Tracking (Series 4+):

- Practice mindfulness for at least 10 minutes
- Keep your arm relatively still
- Allow time for multiple HRV samples
- HRV readings appear less frequently than heart rate

### For Respiratory Rate (Series 6+):

- Stay still during mindfulness sessions
- Allow natural breathing (don't force it)
- Respiratory rate may take longer to appear
- Works best when you're relaxed and breathing naturally

### For Temperature (Series 8+):

- Most accurate readings occur during sleep
- during mindfulness sessions, changes may be subtle
- Temperature trends are more meaningful than single readings
- Ensure watch is in contact with your wrist

---

## Checking Your Watch Model

**To identify your Apple Watch model:**

1. **On iPhone:**

   - Open **Watch** app
   - Go to **General** → **About**
   - Look for "Model" or "Version"

2. **On Apple Watch:**

   - Open **Settings**
   - Go to **General** → **About**
   - Check model information

3. **Physical Identification:**
   - Check the back of your watch
   - Model number is engraved on the case
   - Compare with Apple's model identification guide

---

## Upgrading Considerations

If you're considering upgrading your Apple Watch for better Plena features:

**Minimum for Full Experience:**

- **Series 6** - Gets you heart rate, HRV, and respiratory rate
- **Series 8/Ultra** - Adds temperature tracking

**Best Value:**

- **Series 6 or 7** - All core mindfulness sensors
- **Series 8/Ultra** - Complete sensor suite including temperature

**Latest Technology:**

- **Series 9+** - Enhanced sensors and accuracy

---

## Frequently Asked Questions

**Q: Can I use Plena with an older Apple Watch?**
A: Yes! Plena works with any Apple Watch that supports HealthKit (Series 1+). However, you'll only see sensors that your watch model supports.

**Q: Will upgrading my watch give me more features?**
A: Yes. Newer watches support more sensors, which means more data and insights in Plena.

**Q: Can I see which sensors my watch supports in the app?**
A: Currently, Plena will show "Sensor Unavailable" if your watch doesn't support a sensor. We're working on adding model detection to show available sensors.

**Q: Do I need the latest watch for basic mindfulness tracking?**
A: No! Heart rate tracking works on all Apple Watch models. HRV requires Series 4+, and respiratory rate requires Series 6+.

**Q: Will Plena work if I don't have an Apple Watch?**
A: Plena requires an Apple Watch to collect sensor data. The iPhone app can display and analyze data, but sensors are on the watch.

---

## Summary

Understanding your Apple Watch model's capabilities helps you:

- Know what data you can collect
- Set realistic expectations for features
- Make informed decisions about upgrades
- Troubleshoot sensor availability issues

**Key Takeaways:**

- **Heart Rate:** Available on all watches
- **HRV:** Requires Series 4+
- **Respiratory Rate:** Requires Series 6+
- **Temperature:** Requires Series 8/Ultra+
- **VO₂ Max:** Available on Series 3+ (accuracy varies)

For the best Plena experience, we recommend Apple Watch Series 6 or later for comprehensive mindfulness tracking.

---

_For troubleshooting sensor issues, see [Troubleshooting Guide](TROUBLESHOOTING.md)._
_For setup instructions, see [User Guide](USER_GUIDE.md)._
