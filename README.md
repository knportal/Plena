# Plena Meditation Tracking Sensor App

A meditation tracking application for iPhone and Apple Watch that monitors biometric data during meditation sessions using HealthKit.

## Features

- **Real-time Sensor Tracking**
  - HRV (SDNN) monitoring
  - Heart Rate tracking
  - Respiratory Rate monitoring
  - Body Temperature tracking
  - VO₂ Max tracking
  - Stress zone classification (Calm, Optimal, Elevated Stress)

- **Apple Watch Integration**
  - Start/Stop meditation sessions with 3-2-1 countdown
  - Display real-time sensor data on Watch during sessions
  - Live sensor data streaming from Watch to iPhone
  - Companion app for iPhone shows timer during sessions
  - Automatic data sync between devices
  - Post-session data package transfer

- **Comprehensive Dashboard**
  - Session statistics (total sessions, time, streak)
  - Trend analysis with interactive charts
  - Session frequency visualization
  - Duration trend tracking
  - HRV insights and personalized recommendations
  - Time range views: Day, Week, Month, Year

- **Readiness Score**
  - Daily readiness score calculation
  - Multiple contributors: Resting Heart Rate, HRV Balance, Body Temperature, Recovery Index, Sleep metrics
  - Detailed contributor breakdowns
  - Historical comparison (today vs yesterday)
  - Holistic view of recovery and readiness

- **Data Visualization** (iPhone)
  - Interactive graphs for each sensor
  - Multiple view modes: Consistency and Trend
  - Range indicators (above/normal/below)
  - Time-based views: day, week, month, year
  - Zone distribution analysis
  - Trend statistics and insights

## Project Structure

```
Plena/
├── Plena/                          # iOS App
│   ├── PlenaApp.swift             # App entry point
│   ├── ContentView.swift          # Main view
│   ├── Views/                     # iOS-specific views
│   └── Info.plist                 # iOS app configuration
│
├── Plena Watch App/               # watchOS App
│   ├── PlenaWatchApp.swift       # Watch app entry point
│   ├── WatchContentView.swift     # Main watch view
│   ├── Views/                     # Watch-specific views
│   └── Info.plist                 # Watch app configuration
│
├── PlenaShared/                   # Shared code
│   ├── Models/                    # Data models
│   ├── Services/                  # Business logic (HealthKit, etc.)
│   └── ViewModels/                # MVVM view models
│
├── documents/                     # Project documentation
│   ├── README.md                  # Documentation index
│   ├── APP_OVERVIEW.md           # App overview
│   ├── USER_GUIDE.md             # User guide
│   ├── TROUBLESHOOTING.md        # Troubleshooting
│   └── [App Store docs]          # App Store submission docs
│
├── support/                       # Support website content
│   └── [User-facing support docs]
│
├── docs/                          # Development documentation
│   ├── development/              # Implementation docs
│   ├── setup/                     # Setup guides
│   ├── troubleshooting/           # Dev troubleshooting
│   └── guides/                    # Development guides
│
└── archive/                       # Historical backups
```

## Architecture

- **MVVM Pattern**: Separation of concerns with ViewModels
- **SwiftUI**: Modern declarative UI framework
- **CoreData**: Data persistence framework
- **HealthKit**: Health and fitness data integration
- **CloudKit**: Optional iCloud sync between devices
- **Dependency Injection**: Testable components
- **Async/Await**: Modern concurrency patterns

## Setup Instructions

1. Open `Plena.xcodeproj` in Xcode
2. **Set minimum deployment targets:**
   - iOS: **17.0**
   - watchOS: **10.0**
3. Configure signing for both iOS and watchOS targets
4. Set bundle identifiers:
   - iOS: `com.plena.meditation.app` (or your preferred identifier)
   - watchOS: `com.plena.meditation.app.watchkitapp`
5. **Enable CloudKit (optional but recommended):**
   - Select project → Signing & Capabilities
   - Add "CloudKit" capability to both targets
   - This enables automatic iPhone/Watch data sync
6. Build and run on device (HealthKit requires physical device)

## Requirements

- **iOS 17.0+**
- **watchOS 10.0+**
- Xcode 15.0+
- Physical device (HealthKit doesn't work in simulator)

## Data Persistence

- **CoreData**: Data persistence framework for local storage
- **CloudKit Sync**: Optional iCloud sync between iPhone and Watch (when enabled)
- **HealthKit Integration**: Reads and writes health data through Apple's HealthKit framework
- **Historical Import**: Import existing HealthKit data (see `docs/guides/HEALTHKIT_IMPORT_USAGE.md`)

## Documentation

- **User Documentation**: See `documents/` folder for user guides and App Store documentation
- **Support Content**: See `support/` folder for support website content
- **Development Docs**: See `docs/` folder for implementation and setup guides
- **Archive**: See `archive/` folder for historical backups

## HealthKit Permissions

The app requires HealthKit permissions for:

- **Reading**: Heart Rate, HRV (SDNN), Respiratory Rate, Body Temperature, VO₂ Max, Sleep data, Resting Heart Rate
- **Writing**: Meditation session data (Mindfulness sessions)

## Development Status

✅ **Production Ready** - Core features complete and tested.

**Last Updated:** January 1, 2026

## License

[Add your license here]
