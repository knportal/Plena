# Plena Meditation Tracking Sensor App

A meditation tracking application for iPhone and Apple Watch that monitors biometric data during meditation sessions using HealthKit.

## Features

- **Real-time Sensor Tracking**

  - HRV (SDNN) monitoring
  - Heart Rate tracking
  - Respiratory Rate monitoring
  - State of Mind logging

- **Apple Watch Integration**

  - Start/Stop meditation sessions with 3-2-1 countdown
  - Display one sensor at a time with scrolling
  - Companion app for iPhone

- **Data Visualization** (iPhone)
  - Visually appealing graphs for each sensor
  - Range indicators (above/normal/below)
  - Time-based views: day, week, month, year
  - Manual data import/entry

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
└── PlenaShared/                   # Shared code
    ├── Models/                    # Data models
    ├── Services/                  # Business logic (HealthKit, etc.)
    └── ViewModels/                # MVVM view models
```

## Architecture

- **MVVM Pattern**: Separation of concerns with ViewModels
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Modern data persistence (iOS 17+)
- **HealthKit**: Health and fitness data integration
- **Dependency Injection**: Testable components
- **Async/Await**: Modern concurrency patterns

## Setup Instructions

1. Open `Plena.xcodeproj` in Xcode
2. **Set minimum deployment targets:**
   - iOS: **17.0** (required for SwiftData)
   - watchOS: **10.0** (required for SwiftData)
3. Configure signing for both iOS and watchOS targets
4. Set bundle identifiers:
   - iOS: `com.plena.app`
   - watchOS: `com.plena.app.watchkitapp`
5. **Enable CloudKit (optional but recommended):**
   - Select project → Signing & Capabilities
   - Add "CloudKit" capability to both targets
   - This enables automatic iPhone/Watch data sync
6. Build and run on device (HealthKit requires physical device)

## Requirements

- **iOS 17.0+** (SwiftData requirement)
- **watchOS 10.0+** (SwiftData requirement)
- Xcode 15.0+
- Physical device (HealthKit doesn't work in simulator)

## Data Persistence

- **SwiftData**: Modern, Swift-native persistence framework
- **Automatic Migration**: JSON data automatically migrates to SwiftData on first launch
- **CloudKit Sync**: Optional iCloud sync between iPhone and Watch (when enabled)
- **Historical Import**: Import existing HealthKit data (see `HEALTHKIT_IMPORT_USAGE.md`)

## HealthKit Permissions

The app requires HealthKit permissions for:

- Reading: Heart Rate, HRV (SDNN), Respiratory Rate
- Writing: Meditation session data

## Development Status

🚧 **In Progress** - Project structure and initial setup complete.

## License

[Add your license here]
