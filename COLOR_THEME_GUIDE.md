# Plena Color Theme Guide

## Overview

Plena uses a calming, meditation-focused color palette that adapts automatically to light and dark mode. All colors are defined in asset catalogs for easy theming and consistency.

## Color Sets

### Primary Colors

- **PlenaPrimary**: Calm teal/cyan - Main UI elements, primary actions
- **PlenaSecondary**: Soft sage green - Secondary elements, accents
- **AccentColor**: Gentle lavender/purple - Highlights, special emphasis

### Background Colors

- **BackgroundColor**: Soft off-white (light) / Deep navy (dark) - Main app background
- **CardBackgroundColor**: Pure white (light) / Dark gray (dark) - Card and surface backgrounds

### Text Colors

- **TextPrimaryColor**: Dark charcoal (light) / Off-white (dark) - Primary text
- **TextSecondaryColor**: Medium gray (light) / Light gray (dark) - Secondary text

### Sensor-Specific Colors

- **HeartRateColor**: Soft coral/rose - Heart rate icons and data
- **HRVColor**: Calm blue - HRV icons and data
- **RespiratoryColor**: Soft mint green - Respiratory rate icons and data
- **VO2MaxColor**: Soft peach/orange - VO2 Max icons and data
- **TemperatureColor**: Gentle purple/lavender - Temperature icons and data

### Status Colors

- **SuccessColor**: Soft green - Positive indicators, improvements
- **WarningColor**: Soft amber - Warnings, cautions, destructive actions

## Usage in Code

Instead of hardcoded colors:

```swift
// ❌ Old way
.foregroundColor(.red)
.foregroundColor(.blue)

// ✅ New way
.foregroundColor(Color("HeartRateColor"))
.foregroundColor(Color("PlenaPrimary"))
```

## Color Values

### Light Mode

- Primary: RGB(102, 179, 204) - Calm teal
- Secondary: RGB(140, 191, 166) - Sage green
- Accent: RGB(191, 179, 217) - Lavender
- Heart Rate: RGB(230, 128, 153) - Soft coral
- HRV: RGB(128, 179, 217) - Calm blue
- Respiratory: RGB(153, 217, 179) - Mint green
- VO2 Max: RGB(242, 179, 153) - Soft peach
- Temperature: RGB(217, 179, 230) - Gentle purple
- Success: RGB(128, 204, 153) - Soft green
- Warning: RGB(242, 191, 153) - Soft amber

### Dark Mode

All colors are slightly brighter and more saturated for better visibility in dark mode while maintaining the calming aesthetic.

## Benefits

1. **Consistency**: All colors are centralized and consistent across the app
2. **Theme Support**: Automatic light/dark mode adaptation
3. **Easy Updates**: Change colors in one place (asset catalog) to update the entire app
4. **Calming Aesthetic**: Soft, muted colors designed for meditation and mindfulness
5. **Accessibility**: Colors chosen for good contrast and readability

## Future Enhancements

- Add more color variants for different meditation themes
- Support for custom user themes
- High contrast mode support
- Color-blind friendly alternatives
