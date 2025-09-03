# Draconic

A macOS dictation app with global hotkey activation and real-time transcription.

## Setup

### Permissions Required

The app requires network permissions to download the WhisperKit model on first run:

1. Open `draconic.xcodeproj` in Xcode
2. Select the app target → "Signing & Capabilities" tab
3. Under "App Sandbox" → "Network", check **"Outgoing Connections (Client)"**

The app will automatically download the `large-v3` WhisperKit model on first launch.

## Development

Open `draconic.xcodeproj` in Xcode and run with Cmd+R.