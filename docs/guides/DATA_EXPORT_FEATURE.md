# Data Export Feature Documentation

## Overview

The Data Export feature allows premium subscribers to export their meditation session data as CSV files for analysis, backup, or sharing with healthcare providers.

## Premium Feature Gate

Data export is **only available to users with active monthly or annual premium subscriptions**. The feature checks `PremiumFeature.dataExport` access through the `FeatureGateService`.

## Implementation

### Core Components

1. **DataExportService** (`PlenaShared/Services/DataExportService.swift`)
   - Handles CSV generation for session data
   - Supports two export formats:
     - **Session Summary**: One row per session with aggregated statistics
     - **Detailed Data**: All sensor samples with timestamps

2. **DataExportView** (`Plena/Views/DataExportView.swift`)
   - User interface for selecting export options
   - Date range picker for filtering sessions
   - Export type selector (Summary vs. Detailed)
   - Share sheet integration for saving/sharing files

3. **Settings Integration** (`Plena/Views/SettingsView.swift`)
   - "Export Data" button in Settings → Data section
   - Shows premium badge (⭐) if user doesn't have access
   - Displays paywall if non-premium user attempts export

### Export Formats

#### Session Summary CSV

**Columns:**
- Session ID
- Start Date (ISO8601)
- End Date (ISO8601)
- Duration (minutes)
- Heart Rate Samples (count)
- HRV Samples (count)
- Respiratory Rate Samples (count)
- Temperature Samples (count)
- VO2 Max Samples (count)
- Avg Heart Rate (BPM)
- Avg HRV (ms)
- Avg Respiratory Rate (breaths/min)
- Avg Temperature (°C)
- Device Type

**Use Case:** Overview analysis, trend identification, session statistics

#### Detailed Data CSV

**Columns:**
- Session ID
- Session Start (ISO8601)
- Sample Type
- Sample Timestamp (ISO8601)
- Value
- Unit

**Sample Types:**
- Heart Rate (BPM)
- HRV (SDNN) (ms)
- Respiratory Rate (breaths/min)
- Temperature (°C)
- VO2 Max (ml/kg/min)

**Use Case:** Deep analysis, scientific research, detailed data exploration

## User Flow

1. User navigates to **Settings** → **Data** section
2. Taps **"Export Data"**
3. If not premium:
   - Paywall appears showing the Data Export feature
   - User can subscribe or dismiss
4. If premium:
   - Export options screen appears
   - User selects export type (Summary or Detailed)
   - User selects date range
   - App shows count of sessions to export
   - User taps "Export Data"
   - Share sheet appears with the CSV file
   - User can save to Files, share via AirDrop, email, etc.

## Technical Details

### Date Formatting

- **ISO8601 with fractional seconds** for timestamps
- Ensures compatibility with data analysis tools (Excel, Python, R, etc.)
- Format: `2025-01-01T14:30:00.000Z`

### File Generation

- Files created in temporary directory
- Named: `plena_sessions_summary.csv` or `plena_sessions_detailed.csv`
- Cleaned up automatically by iOS after sharing

### Data Loading

- Uses `CoreDataStorageService` to load sessions
- Efficient loading with `loadSessionsWithoutSamples` for counting
- Full data loading only when exporting

### Error Handling

- `ExportError.noSessionsToExport`: No sessions in selected date range
- `ExportError.fileCreationFailed`: Unable to write file
- `ExportError.encodingFailed`: Data encoding error

All errors display user-friendly alert messages.

## Testing

Unit tests provided in `Tests/DataExportServiceTests.swift`:

- Session summary export with valid data
- Detailed export with valid data
- Error handling for empty session lists
- CSV format validation
- Sample counting verification

## Security & Privacy

- **Data remains local**: CSV files are generated locally, never sent to servers
- **Premium-only access**: Feature gated behind subscription
- **User control**: User chooses what to export and where to share
- **Temporary storage**: Files created in iOS temporary directory
- **iOS share sheet**: Uses native iOS sharing for maximum security

## Future Enhancements

Potential improvements for future versions:

1. **Additional Formats**
   - JSON export
   - Excel (.xlsx) format
   - HealthKit-compatible format

2. **Filtering Options**
   - Export specific sessions
   - Filter by duration threshold
   - Filter by sensor availability

3. **Custom Date Presets**
   - Last 7 days
   - Last 30 days
   - Last year
   - All time

4. **Automated Exports**
   - Weekly/monthly automated exports
   - Cloud backup integration (iCloud, Dropbox)

5. **Data Visualization Export**
   - Export chart images
   - PDF reports with visualizations

## Review

**Potential Issues:**
- Large exports with many sessions could be slow (consider adding progress indicator)
- CSV format may not be ideal for users unfamiliar with data analysis (consider adding user guide)
- Date range selection could be improved with presets

**Security Considerations:**
- ✅ Premium-only access enforced
- ✅ Local data processing
- ✅ Native iOS sharing mechanism
- ✅ No server uploads

**Performance Notes:**
- Session counting uses optimized `loadSessionsWithoutSamples`
- Full data loaded only when exporting
- For very large datasets (1000+ sessions), consider pagination or streaming

## Suggestions

1. **Add progress indicator** for large exports (100+ sessions)
2. **Add user guide** in-app explaining how to open CSV files
3. **Add date range presets** for common use cases
4. **Consider adding export preview** showing first few rows before export
5. **Add export history** tracking when/what was exported

---

**Last Updated:** January 1, 2026
**Feature Status:** ✅ Implemented
**Premium Tier:** Monthly & Annual Subscriptions

