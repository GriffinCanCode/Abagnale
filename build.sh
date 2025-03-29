#!/bin/bash

# Build the Swift package
swift build

# Create the app bundle structure
mkdir -p abagnale.app/Contents/MacOS
mkdir -p abagnale.app/Contents/Resources

# Copy the executable
cp .build/debug/abagnale abagnale.app/Contents/MacOS/

# Copy the Info.plist
cp Sources/abagnale/Resources/Info.plist abagnale.app/Contents/

# Make the app executable
chmod +x abagnale.app/Contents/MacOS/abagnale

echo "App bundle created at abagnale.app" 