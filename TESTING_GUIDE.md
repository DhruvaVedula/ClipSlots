# ClipSlots Testing Guide

## Quick Start

### 1. Build the App

In Xcode:
- Press **⌘B** (or Product → Build)
- Wait for "Build Succeeded"

### 2. Copy to Applications

In Terminal:
```bash
cd /Users/dhruvavedula/clipslots
./copy_to_applications.sh
```

Or manually:
- In Finder, press **⌘⇧G** and paste: `~/Library/Developer/Xcode/DerivedData`
- Find the ClipSlots folder (most recent one)
- Navigate to: `Build/Products/Debug/ClipSlots.app`
- Copy `ClipSlots.app` to `/Applications/`

### 3. Run the App

- Double-click `/Applications/ClipSlots.app`
- Or run: `open /Applications/ClipSlots.app`

You should see a **"CS"** icon in your menubar (top right).

---

## Testing Features

### Test 1: Menubar Icon & Menu

1. **Check menubar**: Look for "CS" icon in top-right menubar
2. **Click the icon**: Should open a menu showing:
   - 9 slots (Q, W, E, R, A, S, D, F, Z) - all showing "(empty)"
   - "Store Clipboard To:" section
   - "Clear Slot:" section (empty if no slots have content)
   - "Clear All Slots"
   - "Quit"

### Test 2: Grant Permissions (First Time)

When you first use hotkeys, macOS will prompt for permissions:

1. **Accessibility Permissions** (for copy/paste):
   - System Settings → Privacy & Security → Accessibility
   - Find "ClipSlots" and toggle it ON
   - You may need to remove and re-add it if it doesn't work

2. **Screen Recording Permissions** (for screenshots):
   - System Settings → Privacy & Security → Screen Recording
   - Find "ClipSlots" and toggle it ON
   - Restart the app after granting

### Test 3: Store Text via Hotkey

1. **Select some text** in any app (e.g., Terminal, TextEdit, Google Docs)
2. **Press**: `Ctrl + Cmd + Q` (stores to slot Q)
3. **Check console/logs**: Should see "✅ SUCCESS: Got selected text..."
4. **Open menubar menu**: Slot Q should now show a preview of your text

**Try different slots:**
- `Ctrl + Cmd + W` → stores to slot W
- `Ctrl + Cmd + E` → stores to slot E
- etc.

### Test 4: Paste Text via Hotkey

1. **Make sure a slot has text** (use Test 3)
2. **Click in any text field** (e.g., TextEdit, Notes)
3. **Press**: `Ctrl + Cmd + Shift + Q` (pastes from slot Q)
4. **Text should appear** in the text field

**Try different slots:**
- `Ctrl + Cmd + Shift + W` → pastes from slot W
- etc.

### Test 5: Store via Menu

1. **Copy some text** manually (⌘C)
2. **Open ClipSlots menubar menu**
3. **Click**: "Store Clipboard To:" → "Slot Q"
4. **Check menu**: Slot Q should show the text preview

### Test 6: Paste via Menu

1. **Open ClipSlots menubar menu**
2. **Click on a slot** that has text (e.g., "Q. [preview text...]")
3. **Text should be copied to clipboard**
4. **Paste manually** (⌘V) to verify

### Test 7: Screenshot Capture

1. **Press**: `Ctrl + Cmd + Option + Q` (captures screenshot to slot Q)
2. **Check console**: Should see "✅ Screenshot captured and stored to slot Q"
3. **Open menubar menu**: Slot Q should show "[Image]" with a small thumbnail icon
4. **Click the slot**: Image should be copied to clipboard
5. **Paste** (⌘V) in an image editor or document to verify

**Try different slots:**
- `Ctrl + Cmd + Option + W` → screenshot to slot W
- etc.

### Test 8: Clear Individual Slot

1. **Store something in slot Q** (text or screenshot)
2. **Open menubar menu**
3. **Click**: "Clear Slot:" → "Clear Slot Q"
4. **Check menu**: Slot Q should now show "(empty)"
5. **"Clear Slot Q" option should disappear** from the menu

### Test 9: Clear All Slots

1. **Store content in multiple slots**
2. **Open menubar menu**
3. **Click**: "Clear All Slots"
4. **Check menu**: All slots should show "(empty)"
5. **"Clear Slot:" section should be empty**

### Test 10: Persistence

1. **Store content in several slots** (mix of text and screenshots)
2. **Quit the app** (menubar menu → Quit)
3. **Restart the app** (`open /Applications/ClipSlots.app`)
4. **Open menubar menu**: All your stored content should still be there!

---

## Troubleshooting

### Menubar Icon Not Showing

- Check if app is running: `ps aux | grep ClipSlots`
- Try restarting the app
- Check Console.app for errors

### Hotkeys Not Working

- **Check permissions**: System Settings → Privacy & Security → Accessibility
- **Remove and re-add** ClipSlots in Accessibility settings
- **Restart the app** after granting permissions
- **Run from `/Applications`** (not from Xcode)

### Copy Not Working (Only Clipboard Content Stored)

- **Accessibility permissions** may not be granted
- Try manually copying (⌘C) first, then use the hotkey
- Check console logs for error messages

### Screenshot Not Working

- **Screen Recording permissions** required
- System Settings → Privacy & Security → Screen Recording
- Toggle ClipSlots ON
- Restart the app

### Paste Not Working

- Make sure you're clicking in a text field first
- Check if Accessibility permissions are granted
- Try pasting manually (⌘V) after the hotkey to verify clipboard was updated

---

## Expected Console Output

When working correctly, you should see:

```
ClipSlots: AppDelegate initialized
ClipSlots: Application did finish launching
Registered store hotkey for slot Q: Ctrl+Cmd+Q
Registered paste hotkey for slot Q: Ctrl+Cmd+Shift+Q
Registered screenshot hotkey for slot Q: Ctrl+Cmd+Option+Q
... (for all 9 slots)
Accessibility permissions granted ✓
ClipSlots: Status bar item created successfully
```

When using hotkeys:
```
🔍 Attempting to get selected text via Accessibility API...
✅ SUCCESS: Got selected text via Accessibility API and stored to slot Q
```

---

## Quick Test Checklist

- [ ] Menubar icon appears
- [ ] Menu opens and shows 9 empty slots
- [ ] Store text via hotkey (Ctrl+Cmd+Q)
- [ ] Paste text via hotkey (Ctrl+Cmd+Shift+Q)
- [ ] Store via menu works
- [ ] Paste via menu works
- [ ] Screenshot capture works (Ctrl+Cmd+Option+Q)
- [ ] Image appears in menu with thumbnail
- [ ] Clear individual slot works
- [ ] Clear all slots works
- [ ] Content persists after restart

---

## Next Steps After Testing

If everything works:
- ✅ You're done! The app is fully functional.

If something doesn't work:
- Check the Troubleshooting section above
- Check Console.app for error messages
- Make sure permissions are granted
- Try running from `/Applications` instead of Xcode

