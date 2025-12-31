#!/bin/bash

echo "Creating Xcode project for Spoken Reality..."

# Create a temporary Swift file to use xcodebuild
cat > temp.swift << 'EOF'
import SwiftUI

@main
struct TempApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Hello")
        }
    }
}
EOF

# Use swift package to create project
cd ..
mkdir -p SpokenReality-XcodeProject
cd SpokenReality-XcodeProject

# Initialize as Swift package
swift package init --type executable --name SpokenReality

echo "Project structure created. Now opening in Xcode..."
open Package.swift

