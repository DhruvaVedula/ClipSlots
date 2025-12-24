# Setting Up Proper Code Signing for ClipSlots

## Quick Answer: No Paid Account Needed! ✅

You only need a **free Apple ID** (the same one you use for iCloud, App Store, etc.). No Developer Program membership ($99/year) required for this.

## Steps to Set Up Code Signing

### 1. Open the Project in Xcode

If Xcode isn't already open:
```bash
open ClipSlots/ClipSlots.xcodeproj
```

### 2. Select the Project in Navigator

1. Click **ClipSlots** (blue project icon) in the left sidebar
2. Under **TARGETS**, click **ClipSlots** (the app target, not the project)

### 3. Open Signing & Capabilities Tab

1. Click the **"Signing & Capabilities"** tab at the top
2. You should see a section called **"Signing"**

### 4. Enable Automatic Signing

1. **Check the box** "Automatically manage signing"
2. Under **"Team"**, you'll see a dropdown

### 5. Sign In with Apple ID (if needed)

- If you see **"Add an Account..."** or **"None"** in the Team dropdown:
  - Click **"Add an Account..."**
  - Sign in with your **Apple ID** (the one you use for iCloud)
  - This is **free** - you don't need to enroll in the Developer Program

### 6. Select Your Personal Team

- After signing in, you should see **"Your Name (Personal Team)"** in the Team dropdown
- Select it
- Xcode will automatically:
  - Create a development certificate (if needed)
  - Register the bundle identifier
  - Set up signing

### 7. Verify It's Working

After selecting your Personal Team, you should see:
- ✅ Green checkmark
- ✅ "Provisioning Profile: Xcode Managed Profile"
- ✅ Team name showing (not "None" or "adhoc")

### 8. Build and Test

1. Press **⌘B** to build
2. The app should build successfully with your Personal Team signing

## What This Does

- **Before**: App was signed with "adhoc" signature (changes every build)
- **After**: App is signed with your Personal Team certificate (stable across builds)
- This stable signature is what macOS TCC (permissions) recognizes

## Next Steps After Code Signing

Once code signing is set up:

1. **Build the app** (⌘B in Xcode)
2. **Copy to Applications folder**:
   ```bash
   cp -R ~/Library/Developer/Xcode/DerivedData/ClipSlots-*/Build/Products/Debug/ClipSlots.app /Applications/
   ```
3. **Run from Applications**:
   - Double-click `/Applications/ClipSlots.app`
   - Grant Accessibility permissions when prompted
4. **Test**: The app should now recognize Accessibility permissions correctly!

## Troubleshooting

### "No signing certificate found"
- Xcode needs to create one. Try:
  - Quit and restart Xcode
  - Sign in again: Xcode → Settings → Accounts → Add Apple ID

### "Bundle identifier is already in use"
- This usually resolves automatically
- If not, Xcode will suggest changing it (it will add your name/random suffix)

### Still seeing "adhoc" in code signing output
- Make sure you selected a Team (not "None")
- Try a clean build: Product → Clean Build Folder (⇧⌘K), then build again

## Verification Command

After building, you can verify the signing:

```bash
codesign -dv --verbose=4 /Applications/ClipSlots.app
```

You should see:
- `Authority=` (not "adhoc")
- `TeamIdentifier=` (your team ID)
- `Signature=` (not "adhoc")

