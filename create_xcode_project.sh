#!/bin/bash

# This script creates a proper Xcode project
# We'll use xcrun and templates

PROJECT_NAME="SpokenRealityApp"
BUNDLE_ID="com.spokenreality.app"
PROJECT_DIR="$(pwd)"

echo "Creating Xcode project structure..."

# Create iOS app using xcodebuild templates
cd "$PROJECT_DIR"

# Find Xcode templates
XCODE_PATH=$(xcode-select -p)
TEMPLATE_PATH="$XCODE_PATH/Platforms/iPhoneOS.platform/Developer/Library/Xcode/Templates/Project Templates/iOS/Application"

echo "Xcode path: $XCODE_PATH"
echo "Looking for templates..."

# List available options
ls -la "$TEMPLATE_PATH" 2>/dev/null || echo "Template path not found"

