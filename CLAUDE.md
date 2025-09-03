# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a macOS SwiftUI application called "draconic" built with Xcode. The project uses the modern Swift Testing framework and targets macOS 15.4+.

## Project Structure

- `draconic/` - Main application source code
  - `draconicApp.swift` - App entry point with WindowGroup scene
  - `ContentView.swift` - Main UI view (SwiftUI)
  - `draconic.entitlements` - App sandbox entitlements (read-only file access)
  - `Assets.xcassets/` - App assets and resources
- `draconicTests/` - Unit tests using Swift Testing framework
- `draconicUITests/` - UI tests for the application
- `draconic.xcodeproj/` - Xcode project configuration

## Key Configuration

- **Target Platform**: macOS 15.4+
- **Bundle ID**: `com.ethanmick.draconic` 
- **Swift Version**: 5.0
- **Testing Framework**: Swift Testing (modern `@Test` syntax, not XCTest)
- **UI Framework**: SwiftUI with Preview support
- **Sandboxing**: App sandbox enabled with read-only file access

## Development Commands

Since this is an Xcode project, development should primarily be done through Xcode IDE. Command line builds require full Xcode installation (not just Command Line Tools).

### Building and Running
- Open `draconic.xcodeproj` in Xcode
- Use Cmd+R to build and run
- Use Cmd+U to run tests

### Testing
- Unit tests in `draconicTests/` use Swift Testing framework
- Use `@Test` attribute instead of XCTest's `func test*` pattern
- UI tests available in `draconicUITests/`

## Architecture Notes

- Standard SwiftUI app structure with `@main` App protocol
- Uses modern Swift concurrency (`async throws` in tests)
- Follows SwiftUI declarative patterns
- Minimal initial setup - currently displays "Hello, world!" with globe icon

## Platform-Specific Guidelines

**CRITICAL: This is a macOS-only application. DO NOT use iOS-specific APIs.**

### ❌ Avoid iOS-Only APIs:
- `AVAudioSession` (iOS audio session management - not needed on macOS)
- `UIKit` imports or components
- iOS-specific permission patterns
- `UIApplication` or `UIScene` APIs

### ✅ Use macOS APIs:
- `AVAudioEngine` directly (no session management needed)
- `AVCaptureDevice.requestAccess(for: .audio)` for microphone permissions
- `NSWindow`, `NSApplication` for native macOS features
- `AppKit` when SwiftUI is insufficient

### Audio Capture Notes:
- Use `audioEngine.inputNode.inputFormat(forBus: 0)` for microphone input
- No `AVAudioSession` configuration required on macOS
- Direct access to `AVAudioEngine` without iOS constraints