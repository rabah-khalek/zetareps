# Fix App Icon Not Showing in Simulator

Your icon configuration is **100% correct**. The issue is likely Xcode/simulator cache.

## Step-by-Step Fix:

1. **Delete app from simulator:**
   - Long press the app icon on simulator home screen
   - Tap the X to delete it
   - Confirm deletion

2. **Clean in Xcode:**
   - Press `Shift+Cmd+K` (Clean Build Folder)
   - Wait for it to complete

3. **Delete Derived Data:**
   - In Xcode: `Xcode` → `Settings` → `Locations`
   - Click the arrow next to "Derived Data" path
   - Find and delete the `ZetaReps-*` folder
   - Close Finder window

4. **Close Xcode completely:**
   - Quit Xcode (Cmd+Q)

5. **Restart Xcode and rebuild:**
   - Open Xcode again
   - Open the project
   - Press `Cmd+R` to build and run
   - Wait for full build to complete

6. **If still not working:**
   - In Simulator: `Device` → `Erase All Content and Settings...`
   - This will reset the simulator completely
   - Then rebuild the app

## Your Current Configuration (All Correct):
✓ 5 icon files exist and are valid PNGs
✓ Contents.json has all 5 entries
✓ Project settings reference AppIcon correctly
✓ All required sizes are present

The icon **will** work - it's just a cache issue.
