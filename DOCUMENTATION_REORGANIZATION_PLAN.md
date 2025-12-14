# Documentation Reorganization Plan

**Date:** December 12, 2025

## Current Issues

1. **Duplicate files** between `documents/` and `support/` folders
2. **Too many files in root** directory (backups, development docs, etc.)
3. **Unclear folder purposes** - need to clarify what goes where

## Proposed Structure

```
Plena/
├── README.md                          # Main project README (KEEP)
├── TESTFLIGHT_DEPLOYMENT_GUIDE.md    # Deployment guide (KEEP in root)
├── MEMORY_OPTIMIZATION_FIX.md        # Recent fix documentation (KEEP in root)
│
├── documents/                         # Project documentation
│   ├── README.md                     # Documentation index
│   ├── APP_OVERVIEW.md              # App overview
│   ├── USER_GUIDE.md                # User guide
│   ├── TROUBLESHOOTING.md           # Troubleshooting
│   ├── APPLE_WATCH_COMPATIBILITY.md # Compatibility guide
│   ├── APP_STORE_METADATA.md        # App Store submission
│   ├── APP_STORE_SCREENSHOTS.md     # Screenshot guide
│   ├── PRIVACY_POLICY.md            # Privacy policy
│   ├── MARKETING_MATERIALS.md       # Marketing content
│   └── COMPATIBILITY_DOCUMENTATION_SUMMARY.md
│
├── support/                           # Support website content (KEEP - different purpose)
│   ├── README.md                     # Support homepage
│   ├── APP_OVERVIEW.md              # Website version (more detailed)
│   ├── USER_GUIDE.md                # Website version
│   ├── TROUBLESHOOTING.md           # Website version
│   ├── PRIVACY_POLICY.md            # Website version
│   └── APPLE_WATCH_COMPATIBILITY.md # Website version
│
├── docs/                             # Development documentation (NEW)
│   ├── development/                  # Implementation docs
│   │   ├── STAGE1_IMPLEMENTATION_SUMMARY.md
│   │   ├── STAGE2_IMPLEMENTATION_SUMMARY.md
│   │   ├── STAGE3_IMPLEMENTATION_SUMMARY.md
│   │   ├── STAGE4_IMPLEMENTATION_SUMMARY.md
│   │   ├── STAGE5_IMPLEMENTATION_SUMMARY.md
│   │   ├── READINESS_SCORE_IMPLEMENTATION_PLAN.md
│   │   ├── ZONE_CLASSIFICATION_IMPLEMENTATION.md
│   │   ├── HEALTHKIT_SESSION_TRACKING_IMPLEMENTATION.md
│   │   ├── SESSION_STATISTICS_DASHBOARD_DESIGN.md
│   │   └── SWIFTDATA_IMPLEMENTATION_SUMMARY.md
│   │
│   ├── setup/                        # Setup guides
│   │   ├── XCODE_SETUP_INSTRUCTIONS.md
│   │   ├── XCODE_STEP_BY_STEP.md
│   │   ├── CORE_DATA_SETUP_INSTRUCTIONS.md
│   │   ├── CORE_DATA_QUICK_START.md
│   │   ├── CORE_DATA_MIGRATION_PLAN.md
│   │   ├── CORE_DATA_MIGRATION_COMPLETE.md
│   │   ├── CORE_DATA_FINAL_STEPS.md
│   │   ├── SWIFTDATA_SETUP_GUIDE.md
│   │   ├── SWIFTDATA_TROUBLESHOOTING.md
│   │   ├── CLOUDKIT_SETUP_CLARIFIED.md
│   │   ├── CREATE_CLOUDKIT_CONTAINER.md
│   │   ├── REGISTER_WATCH_DEVICE.md
│   │   └── CLEANUP_WATCH_INSTALL.md
│   │
│   ├── troubleshooting/              # Development troubleshooting
│   │   ├── FIX_WATCH_BUILD_ERROR.md
│   │   ├── MEMORY_ISSUE_FIX.md
│   │   ├── PERMANENT_FIX_COLOR_WARNINGS.md
│   │   ├── DEBUG_MODE_INSTRUCTIONS.md
│   │   └── SWIFTDATA_TROUBLESHOOTING.md
│   │
│   └── guides/                       # Development guides
│       ├── HEALTHKIT_IMPORT_USAGE.md
│       ├── HEALTHKIT_MEDITATION_MARKERS_ANALYSIS.md
│       ├── HISTORICAL_DATA_IMPORT_ANALYSIS.md
│       ├── TEST_DATA_GENERATION.md
│       ├── AXIS_LABEL_TESTING_GUIDE.md
│       ├── APP_ICON_FIX_GUIDE.md
│       ├── COLOR_THEME_GUIDE.md
│       ├── LOGO_SETUP_INSTRUCTIONS.md
│       ├── MISSING_ICONS_REPORT.md
│       ├── ADD_FILE_TO_PROJECT.md
│       ├── FIND_CODEGEN_SETTING.md
│       └── FIND_MEDITATIONSESSIONDATA.md
│
├── archive/                           # Old backups and archives (NEW)
│   ├── BACKUP_2024-12-04_172524.md
│   ├── BACKUP_2025-12-05_083951.md
│   ├── BACKUP_2025-12-05_121939.md
│   ├── BACKUP_2025-12-05_155929.md
│   ├── BACKUP_2025-12-08_111113.md
│   ├── BACKUP_CURRENT_STATE.md
│   ├── BACKUP_DATA_VISUALIZATION_STAGE1.md
│   ├── BACKUP_DATA_VISUALIZATION_STAGE2.md
│   ├── BACKUP_DATA_VISUALIZATION_STAGE3.md
│   ├── BACKUP_DATA_VISUALIZATION_STAGE4.md
│   ├── BACKUP_DATA_VISUALIZATION_STAGE5.md
│   ├── PROJECT_BACKUP_2025-12-08_202707.md
│   ├── PROJECT_BACKUP_2025-12-08_202715.md
│   ├── PROJECT_BACKUP_2025-12-12_080437.md
│   └── PROJECT_SNAPSHOT.md
│
└── scripts/                          # Utility scripts (NEW - if needed)
    ├── add_missing_files_to_project.py
    ├── analyze_and_fix_icon.py
    ├── remove_edge_border.py
    ├── remove_icon_border.py
    └── [shell scripts]
```

## Folder Purposes

### `documents/`
- **Purpose:** Project documentation for developers and App Store submission
- **Audience:** Developers, App Store reviewers
- **Content:** User guides, App Store metadata, marketing materials, technical docs

### `support/`
- **Purpose:** Support website content (if hosting a support site)
- **Audience:** End users seeking help
- **Content:** FAQ, troubleshooting, user guides (more user-friendly versions)

### `docs/`
- **Purpose:** Development and implementation documentation
- **Audience:** Developers working on the project
- **Content:** Implementation summaries, setup guides, development troubleshooting

### `archive/`
- **Purpose:** Historical backups and snapshots
- **Audience:** Reference only
- **Content:** Old backups, project snapshots

## Action Items

1. ✅ Create `docs/` folder structure
2. ✅ Move development docs to `docs/development/`
3. ✅ Move setup guides to `docs/setup/`
4. ✅ Move dev troubleshooting to `docs/troubleshooting/`
5. ✅ Move guides to `docs/guides/`
6. ✅ Create `archive/` folder and move backups
7. ✅ Keep `support/` folder (different purpose - website content)
8. ✅ Update any broken references
9. ✅ Clean up root directory

## Notes

- `support/` and `documents/` serve different purposes - keep both
- `support/` is for a potential support website (more user-friendly)
- `documents/` is for project documentation (more technical)
- Root should only have essential files (README, deployment guides, recent fixes)

