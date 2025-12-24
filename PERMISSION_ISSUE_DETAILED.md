# ClipSlots Accessibility Permission Issue - Detailed Report

## Quick Summary (For AI Agents)

**TL;DR**: macOS menubar app cannot access Accessibility API despite permissions being enabled in System Settings. The app runs from Xcode's DerivedData folder with adhoc code signing. Permission checks (`AXIsProcessTrustedWithOptions`, `AXIsProcessTrusted`) return `false`, and Accessibility API calls fail with `.apiDisabled` error (-25204). Keyboard simulation via `CGEvent` posts events but doesn't trigger system copy/paste. Need solution to read selected text automatically without manual copy step.

**Key Facts**:
- ✅ Permissions enabled in System Settings
- ❌ Permission APIs return false at runtime
- ❌ Accessibility API returns `.apiDisabled` error
- ⚠️ App is adhoc-signed and runs from DerivedData
- ⚠️ Keyboard simulation doesn't work

## Problem Summary
The ClipSlots macOS menubar app cannot access selected text using the Accessibility API, even though Accessibility permissions are enabled in System Settings > Privacy & Security > Accessibility. The permission check consistently returns `false` even though the app is toggled ON in System Settings.

## What We're Trying to Accomplish
We want to implement a hotkey feature where:
1. User selects text in any application
2. User presses a hotkey (e.g., Ctrl+Cmd+Q)
3. The app should automatically copy the selected text and store it in a slot
4. **No manual copy step should be required** - the app should read selected text directly

## What's Currently Working
- ✅ App launches successfully
- ✅ Menubar icon displays ("CS")
- ✅ Menu with 9 slots displays correctly
- ✅ Hotkeys register successfully (Ctrl+Cmd+Q through Ctrl+Cmd+Z)
- ✅ Hotkeys trigger the correct handlers
- ✅ Clipboard operations work (can read/write clipboard)
- ✅ Fallback: Can store clipboard content if user manually copies first
- ✅ App persistence (slots save to disk)

## What's NOT Working
- ❌ Accessibility permissions are not recognized by the app
- ❌ Cannot read selected text using Accessibility API
- ❌ Keyboard simulation (CGEvent/Cmd+C) doesn't work (events posted but clipboard doesn't update)
- ❌ User must manually copy text (⌘C) before using hotkey to store it

## Detailed Error Messages

### Permission Check
```
Permission check - AXIsProcessTrustedWithOptions: false, AXIsProcessTrusted: false
⚠️ WARNING: Accessibility permissions NOT granted
   Bundle ID: com.clipslots.ClipSlots
   App Path: /Users/dhruvavedula/Library/Developer/Xcode/DerivedData/ClipSlots-ggvmxmdzojetmycpfscbryoonqhm/Build/Products/Debug/ClipSlots.app
```

### Accessibility API Call
```
🔍 Attempting to get selected text via Accessibility API...
Trying to get selected text from: Xcode (PID: 16890)
ERROR: Could not get focused element: API disabled (need permissions)
❌ Accessibility API failed - selection copy not available
```

### Keyboard Simulation Attempt
```
Attempting to simulate Cmd+C...
Cmd+C events posted
📋 After copy simulation - clipboard: '...' (unchanged)
❌ Clipboard unchanged - copy simulation may have failed
```

## System Configuration
- **macOS Version**: 26.1.0 (likely Sequoia or newer)
- **Xcode Version**: 26.2
- **App Bundle ID**: `com.clipslots.ClipSlots`
- **App Sandbox**: Disabled (`ENABLE_APP_SANDBOX = NO`)
- **Code Signing**: Ad-hoc signature (running from Xcode)
- **App Type**: LSUIElement (menubar-only, no dock icon)

## Permission Status in System Settings
- ClipSlots **IS ENABLED** in System Settings > Privacy & Security > Accessibility
- Toggle is ON (blue/checked)
- We've tried toggling OFF and back ON multiple times
- App has been fully quit and restarted multiple times

## Code Implementation Details

### Permission Check Code
```swift
// Location: KeystrokeSimulator.swift, AppDelegate.swift

// Method 1: New API
let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
let hasAccessNew = AXIsProcessTrustedWithOptions(options as CFDictionary)
// Returns: false

// Method 2: Old API
let hasAccessOld = AXIsProcessTrusted()
// Returns: false

// Both APIs consistently return false
```

### Accessibility API Usage
```swift
// Location: SelectedTextGetter.swift

// Get frontmost app
let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier
let appElement = AXUIElementCreateApplication(pid)

// Try to get focused element
var focusedElement: CFTypeRef?
let result = AXUIElementCopyAttributeValue(
    appElement, 
    kAXFocusedUIElementAttribute as CFString, 
    &focusedElement
)
// Result: .apiDisabled (error code -25204)
```

### Keyboard Simulation Code
```swift
// Location: KeystrokeSimulator.swift

// Create and post Cmd+C events
let source = CGEventSource(stateID: .hidSystemState)
let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
keyDownEvent.flags = .maskCommand
keyDownEvent.post(tap: .cghidEventTap)
// Events are posted but have no effect - clipboard doesn't change
```

## What We've Tried

1. ✅ **Multiple permission check methods**
   - `AXIsProcessTrustedWithOptions` with prompt enabled/disabled
   - `AXIsProcessTrusted()` (old API)
   - Both consistently return false

2. ✅ **Disabled App Sandbox**
   - Changed `ENABLE_APP_SANDBOX` from YES to NO
   - No change in behavior

3. ✅ **Toggled permissions in System Settings**
   - Turned ClipSlots OFF, waited, turned ON
   - Restarted app multiple times
   - No change

4. ✅ **Keyboard simulation methods**
   - Used `CGEvent.post(tap:)` with `.cghidEventTap`
   - Used `.cgAnnotatedSessionEventTap`
   - Posted to both taps simultaneously
   - Used proper event source (`CGEventSource(stateID: .hidSystemState)`)
   - Events post successfully but don't trigger copy action

5. ✅ **AppleScript approach**
   - Tried `tell application "System Events" to keystroke "c" using command down`
   - Error: "Not authorized to send Apple events to System Events" (error -1743)

6. ✅ **Improved Accessibility API implementation**
   - Multiple methods to get selected text:
     - `kAXSelectedTextAttribute` (direct selected text)
     - `kAXSelectedTextRangeAttribute` + `kAXValueAttribute` (extract from range)
     - `kAXTextAttribute` (fallback)
   - All fail with "API disabled"

## Code Signing Details

**Current Signature Status**:
```
Signature=adhoc
TeamIdentifier=not set
CodeDirectory v=20400 size=560 flags=0x2(adhoc)
```

The app is signed with an **adhoc signature**, meaning it's not properly code-signed with a Developer ID certificate. This is typical for apps built and run directly from Xcode during development.

## Root Cause Hypothesis

**Primary Hypothesis**: When running from Xcode, the app's path is in `DerivedData/ClipSlots-*/Build/Products/Debug/`, which may change between builds. macOS may be treating each build as a different application, so permissions granted to one build don't apply to the next.

**Secondary Hypothesis**: The app is code-signed with an "adhoc" signature (not properly signed), which might cause macOS to not fully trust it for Accessibility API access, even if enabled in System Settings. **CONFIRMED**: Code signing shows `Signature=adhoc`.

**Tertiary Hypothesis**: There may be a macOS security restriction where apps launched from Xcode's debugger context don't receive full Accessibility API access, even with permissions enabled. This is a known issue where macOS's security model restricts Accessibility API access for unsigned or adhoc-signed apps running from development locations.

**Quaternary Hypothesis**: macOS may require a specific bundle identifier format or the app may need to be in a trusted location (Applications folder) for Accessibility API to work, even with permissions enabled.

## Tested Scenarios

1. **Running from Xcode** ❌ - Permissions not recognized
2. **Running from Finder** - Not yet tested by user
3. **Running with Debug build** ❌ - Permissions not recognized
4. **Multiple app restarts** ❌ - No change

## Expected Behavior

When permissions work correctly:
1. `AXIsProcessTrustedWithOptions()` should return `true`
2. `AXUIElementCopyAttributeValue()` should succeed
3. Selected text should be readable without keyboard simulation
4. User should be able to press hotkey and have selected text automatically copied and stored

## Actual Behavior

1. `AXIsProcessTrustedWithOptions()` returns `false`
2. `AXUIElementCopyAttributeValue()` fails with `.apiDisabled` error
3. Keyboard simulation posts events but has no effect
4. User must manually copy text first (⌘C), then use hotkey to store it

## Code Locations

- Permission check: `AppDelegate.swift` line ~50-80
- Permission check helper: `KeystrokeSimulator.swift` line ~17-35
- Accessibility API usage: `SelectedTextGetter.swift` line ~18-101
- Keyboard simulation: `KeystrokeSimulator.swift` line ~37-104
- Hotkey handler: `AppDelegate.swift` line ~186-190

## Additional Context

- The app is a menubar-only app (`INFOPLIST_KEY_LSUIElement = YES` in project.pbxproj)
- Uses Carbon APIs for global hotkeys (`RegisterEventHotKey`)
- Uses AppKit for UI (`NSStatusItem`, `NSMenu`)
- All hotkey registration succeeds
- No build errors or warnings related to Accessibility
- App sandbox is disabled (`ENABLE_APP_SANDBOX = NO`)
- Bundle identifier: `com.clipslots.ClipSlots`
- No Info.plist file found (settings are in project.pbxproj)

## Error Codes Observed

- **AXError.apiDisabled**: Returned when calling `AXUIElementCopyAttributeValue()` - indicates Accessibility API is disabled for this process
- **OSStatus -25204**: The numeric value for `kAXErrorAPIDisabled`
- The error specifically occurs when trying to access `kAXFocusedUIElementAttribute` from the frontmost application

## Permission Check Behavior

Both permission check APIs return false:
- `AXIsProcessTrustedWithOptions()` → `false`
- `AXIsProcessTrusted()` → `false`

However, the app **is enabled** in System Settings. This suggests macOS is not recognizing the running app instance as the same app that has permissions enabled in System Settings.

## macOS Behavior Pattern

This appears to be a known issue with macOS's security model:
1. Apps launched from Xcode/DerivedData may be treated as "untrusted" even with permissions
2. Adhoc-signed apps may have restricted Accessibility API access
3. The app path in DerivedData changes between builds, causing macOS to treat each build as a different app
4. macOS may require the app to be in `/Applications` or properly code-signed for full Accessibility API access

## Questions for Further Investigation

1. Is there a way to force macOS to recognize Accessibility permissions for apps running from Xcode/DerivedData?
2. Would proper code signing (not adhoc) fix this issue?
3. Is there an alternative API or method to read selected text that doesn't require Accessibility permissions?
4. Are there any Info.plist keys or entitlements that need to be set?
5. Could this be a macOS version-specific issue (macOS 26.1.0)?
6. Is there a way to programmatically trigger the permission prompt that actually works?

## File Structure

```
/Users/dhruvavedula/clipslots/
├── ClipSlots/
│   ├── ClipSlots/
│   │   ├── AppDelegate.swift         (main app logic, permission checks)
│   │   ├── KeystrokeSimulator.swift  (keyboard simulation, permission check)
│   │   ├── SelectedTextGetter.swift  (Accessibility API access)
│   │   ├── HotkeyManager.swift       (Carbon hotkey registration)
│   │   ├── SlotStore.swift           (slot persistence)
│   │   ├── ClipboardSlot.swift       (data model)
│   │   └── main.swift                (entry point)
│   └── ClipSlots.xcodeproj/
│       └── project.pbxproj           (Xcode project settings)
└── PERMISSION_ISSUE_DETAILED.md      (this file)
```

## Next Steps Suggested

1. Test running the app directly from Finder (not from Xcode)
2. Consider proper code signing with a Developer ID certificate
3. Investigate if there are any entitlements needed in Info.plist
4. Check if macOS Console shows any security/permission denials
5. Test on a different macOS version if possible

## Resources for Investigation

- [Apple Accessibility API Documentation](https://developer.apple.com/documentation/applicationservices/accessibility)
- [AXIsProcessTrustedWithOptions Documentation](https://developer.apple.com/documentation/applicationservices/1425466-axisprocesstrustedwithoptions)
- macOS Security & Privacy documentation
- CGEvent keyboard simulation documentation

