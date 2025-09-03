# IMPLEMENTATION PLAN: Draconic Dictation App

## Overview
Create a simple dictation app with global hotkey activation, real-time transcription, and text insertion into the previously active application.

## Phase 1: Whisper Integration Foundation

### 1. Whisper.cpp Integration - Most Critical First Step
- Add whisper.cpp as Swift Package Manager dependency (prefer WhisperKit or similar Swift wrapper)
- Alternative: Use pre-built whisper.cpp binary with C bridging header
- Download tiny/base model for fast startup

### 2. Basic Audio Capture
- Use `AVAudioEngine` for microphone input
- Buffer audio in 1-2 second chunks for real-time processing
- Simple start/stop recording functionality

### 3. Basic Transcription Pipeline
- Feed audio chunks to whisper
- Display transcribed text in real-time
- Handle partial vs final transcriptions

## Phase 2: Minimal UI

### 4. Floating Window
- Create separate `NSWindow` with:
  - `NSWindowLevel.floating` (stays on top)
  - Semi-transparent background (`NSVisualEffectView`)
  - Center screen positioning
  - Basic text display

### 5. Global Hotkey
- Use Carbon or Cocoa event monitoring
- Single shortcut to activate (e.g., Cmd+Shift+Space)
- Remember previous active app using `NSWorkspace`

### 6. Text Editing
- Simple `TextEditor` in SwiftUI
- Allow editing transcribed text
- Cmd+Enter to confirm and send

## Phase 3: Text Insertion

### 7. Text Injection
- Use `CGEventCreateKeyboardEvent` for typing
- Focus back to previous app using `NSRunningApplication.activate()`
- Basic text insertion (no fancy formatting)

### 8. Permissions & Entitlements
- Microphone permission
- Accessibility permission (for text insertion)
- Input monitoring permission (for global hotkeys)

## MVP Architecture

```
App Structure:
├── Models/
│   ├── AudioCaptureManager.swift (AVAudioEngine wrapper)
│   ├── WhisperManager.swift (transcription)
│   └── TextInsertionManager.swift (typing automation)
├── Views/
│   ├── FloatingWindow.swift (overlay window)
│   └── TranscriptionView.swift (text display/edit)
├── Services/
│   └── GlobalHotkeyManager.swift (keyboard monitoring)
```

## Key MVP Decisions

- **Start with WhisperKit** (Swift wrapper) rather than raw whisper.cpp
- **Use built-in system transparency** rather than custom blur
- **Single global hotkey** (no multiple shortcuts)
- **Basic text typing** (no rich text/formatting)
- **1-line post-processing function** (`processText(_ text: String) -> String`)
- **No settings/preferences** initially

## Implementation Order

1. **Whisper Integration** - Get transcription working in current basic app
2. **Audio Capture** - Real-time microphone input
3. **Floating Window** - Overlay UI with transparency
4. **Global Hotkey** - Activation shortcut
5. **Text Insertion** - Send transcribed text to other apps
6. **Polish & Permissions** - Final touches and system permissions

## Success Criteria

- [ ] User can press global hotkey to activate dictation
- [ ] Floating window appears with semi-transparent background
- [ ] Real-time speech transcription appears in window
- [ ] User can edit transcribed text
- [ ] Cmd+Enter sends text to previously active application
- [ ] Window disappears and focus returns to original app

## Next Steps

Start with whisper integration - this is the foundation everything else builds upon.