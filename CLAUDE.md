# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Draconic is a macOS dictation app with global hotkey activation and real-time transcription. The app uses WhisperKit for on-device speech recognition, provides a floating overlay window, and can insert transcribed text into any application.

## Core Architecture

The app uses a modular architecture with clear separation of concerns:

### Key Components
- **`AudioCaptureManager`** - Handles microphone input and audio processing using `AVAudioEngine`
- **`WhisperManager`** - Manages WhisperKit integration for speech-to-text transcription
- **`GlobalHotkeyManager`** - Registers global hotkey (Cmd+Shift+J) using Carbon APIs
- **`FloatingWindow`** - Creates semi-transparent overlay window for dictation UI
- **`AppDelegate`** - Coordinates app lifecycle and hotkey handling

### Data Flow
1. User presses global hotkey → Shows floating window
2. Audio capture begins → Real-time transcription starts
3. User speaks → WhisperKit processes audio chunks 
4. Text appears in overlay → User can edit if needed
5. Cmd+Enter sends text to active app → Window closes

## Dependencies

- **WhisperKit** - On-device speech recognition (large-v3 model)
- **Swift Collections** - Enhanced data structures
- **Swift Transformers** - ML model support
- **Swift Argument Parser** - CLI argument handling

## Permissions & Entitlements

The app requires these sandbox permissions:
- `com.apple.security.device.audio-input` - Microphone access
- `com.apple.security.network.client` - Download WhisperKit models
- `com.apple.security.automation.apple-events` - Text injection via events

## Development Commands

### Building and Running
```bash
# Open project in Xcode (required for development)
open draconic.xcodeproj

# Build and run: Cmd+R in Xcode
# Run tests: Cmd+U in Xcode
```

**IMPORTANT**: Command line builds require full Xcode installation. For code testing, ask user to build/run in Xcode.

### Testing
- Unit tests use Swift Testing framework (`@Test` syntax)
- UI tests available in `draconicUITests/`
- Audio features require microphone permissions to test fully

## Platform-Specific Guidelines

**CRITICAL: This is a macOS-only application. DO NOT use iOS-specific APIs.**

### ✅ Correct macOS Patterns:
- `AVAudioEngine` for audio capture (no session management needed)
- `AVCaptureDevice.requestAccess(for: .audio)` for microphone permissions
- `NSPanel` with `.floating` level for overlay windows
- Carbon APIs for global hotkeys
- `CGEvent` for text injection
- `NSVisualEffectView` for window transparency

### ❌ Avoid iOS-Only APIs:
- `AVAudioSession` (not needed on macOS)
- `UIKit` imports or components
- iOS-specific permission patterns
- `UIApplication` or `UIScene` APIs

## Key Implementation Details

### Audio Processing
- Captures audio at 16kHz, 16-bit, mono format
- Processes 2-second chunks for real-time transcription
- Maintains 0.5-second overlap for context continuity
- Creates proper WAV headers for WhisperKit compatibility

### Window Management
- Uses `NSPanel` with `.nonactivatingPanel` to avoid stealing focus
- Semi-transparent background with `NSVisualEffectView.hudWindow`
- Captures previous app focus and restores on close
- Handles Escape (cancel) and Cmd+Enter (send) keyboard shortcuts

### Text Insertion
- Temporarily replaces clipboard contents
- Simulates Cmd+V keypress using `CGEvent`
- Restores original clipboard after insertion
- Small delays ensure proper sequencing

## File Organization

```
draconic/
├── draconicApp.swift          # App entry point with AppDelegate
├── ContentView.swift          # Main app window (permission UI)
├── AudioCaptureManager.swift  # AVAudioEngine wrapper
├── WhisperManager.swift       # WhisperKit integration
├── GlobalHotkeyManager.swift  # Carbon hotkey registration  
├── FloatingWindow.swift       # Overlay window + UI
└── draconic.entitlements      # Sandbox permissions
```
