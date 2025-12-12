# How to Find Codegen Setting in Xcode

## Step-by-Step Instructions

### Step 1: Open the Right Inspector Panel
1. Make sure the **right sidebar** is visible
2. If not visible, press **⌥⌘0** (Option + Command + 0) or click the inspector icon in the toolbar

### Step 2: Select an Entity
1. In the **left sidebar** (Entities section)
2. Click on **"MeditationSessionEntity"** (or any entity)
3. Make sure the **entity itself** is selected (not an attribute or relationship)

### Step 3: Open Data Model Inspector
1. In the **right sidebar**, you'll see multiple inspector tabs at the top:
   - File Inspector (document icon)
   - **Data Model Inspector** (ruler/measure icon) ← **Click this one!**
   - Quick Help Inspector (question mark)
2. Click the **Data Model Inspector** tab (ruler icon)

### Step 4: Find Codegen Dropdown
1. In the **Data Model Inspector**, scroll down
2. Look for a section called **"Class"** or **"Codegen"**
3. You should see a dropdown that says:
   - "Class Definition" (recommended)
   - "Category/Extension"
   - "Manual/None"
4. Set it to **"Class Definition"** for each entity

## Visual Guide

```
Right Sidebar (Inspector):
┌─────────────────────┐
│ [File] [📏] [❓]    │ ← Click the ruler icon (Data Model Inspector)
├─────────────────────┤
│ Entity:             │
│ MeditationSession...│
│                     │
│ Class:              │
│ [Class Definition ▼]│ ← This is the Codegen dropdown
│                     │
│ ...                 │
└─────────────────────┘
```

## Alternative: If Codegen Doesn't Appear

If you don't see the Codegen option:

1. **Make sure you selected the ENTITY** (not an attribute)
   - Click on the entity name in the left sidebar
   - The entity name should be highlighted

2. **Check the Inspector Tab**
   - Make sure you're on **Data Model Inspector** (ruler icon)
   - Not File Inspector or Quick Help

3. **Try selecting a different entity**
   - Sometimes Xcode needs a refresh
   - Click another entity, then back

4. **Close and reopen the model file**
   - Close the model editor
   - Reopen `PlenaDataModel.xcdatamodeld`

## What Codegen Does

- **Class Definition**: Auto-generates NSManagedObject classes (recommended)
- **Category/Extension**: Generates extension files
- **Manual/None**: You write the classes yourself

For this project, use **"Class Definition"** - it's the easiest!

## Quick Check

After setting Codegen to "Class Definition":
- Build the project (⌘B)
- You should see auto-generated classes like `MeditationSessionEntity+CoreDataClass.swift`
- No build errors about missing entity types


