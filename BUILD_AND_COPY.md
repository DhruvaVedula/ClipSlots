# Building and Updating ClipSlots

## Quick Answer

**No, it doesn't update automatically.** You need to manually copy the new build to `/Applications` after building in Xcode.

## Workflow

### Option 1: Manual Copy (Simple)

1. **Build in Xcode**: Press **⌘B** (or Product → Build)
2. **Copy to Applications**: Run this command in Terminal:
   ```bash
   ./copy_to_applications.sh
   ```
3. **Run the app**: Double-click `/Applications/ClipSlots.app` or run:
   ```bash
   open /Applications/ClipSlots.app
   ```

### Option 2: Use the Helper Script

I've created `copy_to_applications.sh` that:
- ✅ Finds the latest build automatically
- ✅ Stops any running instances
- ✅ Copies to `/Applications`
- ✅ Shows you what to do next

Just run:
```bash
cd /Users/dhruvavedula/clipslots
./copy_to_applications.sh
```

### Option 3: Manual Copy (If Script Doesn't Work)

1. Build in Xcode (⌘B)
2. In Finder, press **⌘⇧G** and paste:
   ```
   ~/Library/Developer/Xcode/DerivedData
   ```
3. Find the ClipSlots folder (look for the most recent one)
4. Navigate to: `Build/Products/Debug/ClipSlots.app`
5. Copy `ClipSlots.app` to `/Applications` (replace the old one)

## Why Manual Copy?

- Xcode builds to `DerivedData` (a temporary location)
- `/Applications` is where macOS expects stable apps
- TCC (permissions) keys off the app path - so you need to run from `/Applications` for permissions to persist

## Pro Tip

After the first time you set up permissions, you can:
1. Build in Xcode (⌘B)
2. Run `./copy_to_applications.sh`
3. The app will remember your permissions (since it's the same path)

You don't need to re-grant permissions each time - just copy the new build over the old one.

