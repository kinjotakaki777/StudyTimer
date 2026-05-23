#!/bin/bash
set -e

echo "=== Building StudyTimer macOS App ==="

# Define directories
WORKSPACE_DIR="/Users/kinjotakaki/Developer/StudyTimer"
BUILD_DIR="$WORKSPACE_DIR/build"
APP_DIR="$WORKSPACE_DIR/StudyTimer.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

echo "Creating bundle structure..."
mkdir -p "$MACOS_DIR"
mkdir -p "$CONTENTS_DIR/Resources"

# Find SDK path
SDK_PATH=$(xcrun --show-sdk-path --sdk macosx)
echo "Using SDK: $SDK_PATH"

echo "Compiling Swift source files..."
swiftc \
    -o "$MACOS_DIR/StudyTimer" \
    -sdk "$SDK_PATH" \
    -O \
    "$WORKSPACE_DIR/StudyTimer/StudyTimerApp.swift" \
    "$WORKSPACE_DIR/StudyTimer/AppDelegate.swift" \
    "$WORKSPACE_DIR/StudyTimer/TimerManager.swift" \
    "$WORKSPACE_DIR/StudyTimer/RemindersManager.swift" \
    "$WORKSPACE_DIR/StudyTimer/MainPopoverView.swift"

echo "Copying Info.plist..."
cp "$WORKSPACE_DIR/StudyTimer/Info.plist" "$CONTENTS_DIR/Info.plist"

echo "Applying permissions..."
chmod +x "$MACOS_DIR/StudyTimer"

echo "=== Build Successful! ==="
echo "App is ready at: $APP_DIR"
