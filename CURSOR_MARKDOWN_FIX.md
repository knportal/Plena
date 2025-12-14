# Fixing Cursor Markdown File Opening Issues

**Issue:** "Unable to open 'README.md'" with "Assertion Failed: Argument is `undefined` or `null`"

## Quick Fixes

### 1. Reload Cursor Window
- **Cmd+Shift+P** (or **Ctrl+Shift+P** on Windows/Linux)
- Type: `Developer: Reload Window`
- Press Enter

This refreshes Cursor's file system cache and should fix most issues after file reorganization.

### 2. Close and Reopen Cursor
- Close Cursor completely
- Reopen the project
- Try opening the markdown file again

### 3. Clear Cursor Cache (if above doesn't work)
```bash
# Close Cursor first, then run:
rm -rf ~/Library/Application\ Support/Cursor/Cache/*
rm -rf ~/Library/Application\ Support/Cursor/CachedData/*
```

### 4. Reopen from File Explorer
- Use Cursor's file explorer sidebar
- Navigate to the file
- Click to open (instead of using recent files)

### 5. Check File Permissions
```bash
# Ensure files are readable
chmod -R 644 *.md documents/*.md support/*.md docs/**/*.md
```

### 6. Try Opening from Terminal
```bash
# Open specific file
open -a Cursor README.md

# Or use code command if available
code README.md
```

## If Issue Persists

### Check for Corrupted Files
All markdown files should be UTF-8 encoded. If you suspect a file is corrupted:

```bash
# Check file encoding
file README.md

# Should show: "UTF-8 text" or "ASCII text"
```

### Recreate Problematic Files
If a specific file won't open:
1. Copy its content
2. Delete the file
3. Create a new file with the same name
4. Paste the content back

### Disable Markdown Extensions Temporarily
1. Go to Extensions (Cmd+Shift+X)
2. Disable markdown-related extensions
3. Reload window
4. Try opening file
5. Re-enable extensions if needed

## Prevention

After major file reorganizations:
1. **Reload Cursor window** immediately
2. **Close all open files** before moving files
3. **Use Cursor's file explorer** instead of external file moves when possible

---

**Last Updated:** December 12, 2025

