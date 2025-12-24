# Screenshot Crash Debugging - Potential Issues

## Since full-screen works but area selection crashes, here are the likely culprits:

### 1. **Window Cleanup / Deallocation Issues**
- Selection window might be deallocated while still referenced
- Window's contentView might be accessed after window closes
- `ScreenshotSelectionWindow` might not be properly retained/released
- **Check**: Window delegate or observers still active after close

### 2. **Menu Rebuild During Active Selection**
- Menu might be rebuilding while selection window is still active
- `buildMenu()` called while menu is open/displayed
- NSMenuItem references might be invalid
- **Check**: Is menu open when screenshot completes?

### 3. **Threading / Main Thread Violations**
- UI updates happening off main thread
- Window operations on background thread
- Menu updates not on main thread
- **Check**: All UI code must be on main thread

### 4. **Completion Handler Issues**
- Completion called multiple times
- Completion called after ScreenshotManager deallocated
- Weak self becoming nil at wrong time
- **Check**: Is completion handler being retained properly?

### 5. **Memory / Retain Cycles**
- Selection window retaining ScreenshotManager
- ScreenshotManager retaining window
- Completion handler creating retain cycle
- **Check**: Use weak references everywhere

### 6. **Image Data Access After Deallocation**
- Image data being accessed after slot is stored
- NSImage created from deallocated data
- **Check**: Image data should be copied, not referenced

### 7. **Menu Delegate Conflicts**
- `menuWillOpen` being called during rebuild
- Menu delegate methods called while menu is being modified
- **Check**: Menu delegate might be rebuilding menu while it's open

### 8. **StatusItem / Menu Nil Access**
- `statusItem?.menu` becoming nil during rebuild
- Menu being deallocated while items are being added
- **Check**: Menu might be nil when buildMenu() is called

### 9. **Coordinate Conversion Issues**
- Screen coordinate calculation causing invalid rect
- Negative coordinates or invalid sizes
- **Check**: Are coordinates valid before passing to screencapture?

### 10. **Process / File System Issues**
- Temp file cleanup happening too early
- Process still running when file is deleted
- **Check**: File operations might be racing

### 11. **Event Handling After Window Close**
- Mouse/keyboard events still being processed after window closes
- Event handlers accessing deallocated views
- **Check**: Events might be queued and processed after close

### 12. **NSApp Activation Issues**
- `NSApp.activate(ignoringOtherApps: true)` causing issues
- App activation conflicting with window operations
- **Check**: Activation might be interfering

## Most Likely Culprits (in order):

1. **Menu rebuild while menu is open** - Most common cause
2. **Window cleanup/deallocation** - Window not properly released
3. **Completion handler timing** - Called at wrong time or multiple times
4. **Threading violations** - UI updates off main thread

## Quick Fixes to Try:

1. **Don't rebuild menu immediately** - Only rebuild when menu opens next
2. **Add delays** - Small delay before window cleanup
3. **Check for nil** - Guard all menu/statusItem accesses
4. **Simplify completion** - Remove nested async calls
5. **Add crash logging** - Use try/catch around suspect code

