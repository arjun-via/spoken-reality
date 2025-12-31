#!/usr/bin/env python3
import os
import subprocess

# Delete the broken project
if os.path.exists("SpokenRealityApp.xcodeproj"):
    subprocess.run(["rm", "-rf", "SpokenRealityApp.xcodeproj"])

print("Creating proper Xcode project...")

# Use Xcode's command line to create a proper project
# We'll use AppleScript to automate Xcode GUI
applescript = '''
tell application "Xcode"
    activate
    delay 1
end tell

tell application "System Events"
    tell process "Xcode"
        keystroke "n" using {command down, shift down}
        delay 2
        
        # Should be on template selection
        # iOS App is usually first, press return
        keystroke return
        delay 1
        
        # Product Name
        keystroke "SpokenRealityApp"
        delay 0.3
        
        # Tab through fields
        repeat 3 times
            keystroke tab
        end repeat
        
        # Next button
        keystroke return
        delay 1
        
        # Save dialog - use keyboard shortcut to navigate
        keystroke "g" using {command down, shift down}
        delay 0.5
        keystroke "/Users/arjundivecha/Dropbox/AAA Backup/A Working/Spoken Reality/"
        keystroke return
        delay 0.5
        
        # Create button
        keystroke return
    end tell
end tell
'''

with open("/tmp/create_xcode_proj.scpt", "w") as f:
    f.write(applescript)

print("\nAttempting to create project via Xcode automation...")
print("This requires accessibility permissions.")

result = subprocess.run(["osascript", "/tmp/create_xcode_proj.scpt"], 
                       capture_output=True, text=True)

if result.returncode != 0:
    print("\n⚠️  Automation failed (needs permissions)")
    print("\nPlease do this manually (30 seconds):")
    print("1. In Xcode: File → New → Project (Cmd+Shift+N)")
    print("2. Choose: iOS → App")
    print("3. Name: SpokenRealityApp")
    print("4. Interface: SwiftUI")
    print("5. Save to this folder")
    print("\nThen I'll add your source files!")
else:
    print("✓ Project created!")

