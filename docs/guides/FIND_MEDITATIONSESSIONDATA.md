# Find and Add MeditationSessionData.swift

## The Issue

You're looking at `MeditationSession.swift` (Codable struct), but the build error is about `MeditationSessionData.swift` (SwiftData @Model class). These are **two different files**.

## Step 1: Check if File Exists in Project Navigator

1. In the **Project Navigator** (left sidebar)
2. Look under: **PlenaShared** → **Models**
3. Do you see **`MeditationSessionData.swift`** in the list?

### If You See It:

- Select `MeditationSessionData.swift`
- Check the **File Inspector** (right sidebar)
- In **"Target Membership"**, verify both targets are checked:
  - ☑ Plena
  - ☑ Plena Watch App

### If You DON'T See It:

The file exists on disk but isn't added to the Xcode project. Follow these steps:

## Step 2: Add MeditationSessionData.swift to Project

### Method A: Add Files Dialog

1. **Right-click** on the **"Models"** folder (in PlenaShared)
2. Select **"Add Files to Plena..."**
3. Navigate to: `PlenaShared/Models/`
4. Find and select **`MeditationSessionData.swift`**
5. In the dialog:
   - ✅ Uncheck "Copy items if needed"
   - ✅ Under "Add to targets", check **BOTH**:
     - ☑ Plena
     - ☑ Plena Watch App
6. Click **"Add"**

### Method B: Drag and Drop

1. Open **Finder**
2. Navigate to: `/Users/kennethnygren/Cursor/Plena/PlenaShared/Models/`
3. Find **`MeditationSessionData.swift`**
4. **Drag it** into Xcode
5. Drop it into the **"Models"** folder in Project Navigator
6. In the dialog:
   - ✅ Uncheck "Copy items if needed"
   - ✅ Check **BOTH** targets (Plena and Plena Watch App)
7. Click **"Finish"**

## Step 3: Verify

After adding:

1. `MeditationSessionData.swift` should appear in Project Navigator
2. Select it
3. File Inspector should show both targets checked
4. Build again (⌘B)

## Quick Check: Search in Project Navigator

1. Click in the **Project Navigator**
2. Press **⌘F** (Command + F) to search
3. Type: `MeditationSessionData`
4. If it appears, click on it
5. Check File Inspector for target membership

## The Two Files

- **`MeditationSession.swift`** = Codable struct (already in project) ✅
- **`MeditationSessionData.swift`** = SwiftData @Model class (needs to be added) ❌

Make sure you're looking for the **Data** version!



