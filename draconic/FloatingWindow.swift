//
//  FloatingWindow.swift
//  draconic
//
//  Created by Ethan Mick on 9/3/25.
//

import SwiftUI
import AppKit

class FloatingWindowController: NSWindowController, ObservableObject {
    @Published var audioManager: AudioCaptureManager?
    @Published var whisperManager: WhisperManager?
    weak var appDelegate: AppDelegate?
    
    convenience init(appDelegate: AppDelegate) {
        let panel = FloatingPanel()
        self.init(window: panel)
        panel.floatingController = self
        self.appDelegate = appDelegate
        setupManagers()
        updateContentView()
    }
    
    private func setupManagers() {
        audioManager = AudioCaptureManager()
        whisperManager = WhisperManager()
        
        // Set up audio capture callbacks
        audioManager?.onStreamingAudioCaptured = { [weak self] audioData in
            Task {
                await self?.whisperManager?.transcribeRealtime(audioData: audioData)
            }
        }
        
        audioManager?.onAudioCaptured = { [weak self] audioData in
            Task {
                await self?.whisperManager?.transcribe(audioData: audioData)
            }
        }
    }
    
    func startListening() async {
        guard let audioManager = audioManager else { return }
        
        if await audioManager.requestMicrophonePermission() {
            audioManager.startRecording()
        } else {
            print("Microphone permission denied")
        }
    }
    
    func pauseListening() {
        audioManager?.pauseRecording()
    }
    
    func resumeListening() {
        audioManager?.resumeRecording()
    }
    
    func stopListening() {
        audioManager?.stopRecording()
    }
    
    func isPaused() -> Bool {
        return audioManager?.isPaused ?? false
    }
    
    func getCurrentTranscription() -> String {
        return whisperManager?.realtimeText.isEmpty == false ? whisperManager?.realtimeText ?? "" : whisperManager?.transcribedText ?? ""
    }
    
    func isTranscribing() -> Bool {
        return whisperManager?.isRealtimeTranscribing == true || whisperManager?.isTranscribing == true
    }
    
    func clearTranscription() {
        whisperManager?.clearText()
    }
    
    private func updateContentView() {
        guard let panel = window as? FloatingPanel else { return }
        
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        
        let content = FloatingWindowContent(windowController: self)
        let hostingView = NSHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        visualEffect.addSubview(hostingView)
        panel.contentView = visualEffect
        
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor)
        ])
    }
}

class FloatingPanel: NSPanel {
    weak var floatingController: FloatingWindowController?
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 250),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        self.collectionBehavior = .canJoinAllSpaces
        
        self.center()
        self.orderFrontRegardless()
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            floatingController?.stopListening()
            floatingController?.clearTranscription()
            self.close()
            return
        }
        
        // Spacebar to pause/resume transcription
        if event.keyCode == 49 { // Spacebar
            if floatingController?.isPaused() == true {
                floatingController?.resumeListening()
            } else {
                floatingController?.pauseListening()
            }
            return
        }
        
        // Enter to finish and send text
        if event.keyCode == 36 { // Enter key
            let transcription = floatingController?.getCurrentTranscription() ?? ""
            if !transcription.isEmpty {
                floatingController?.stopListening()
                floatingController?.appDelegate?.injectText(transcription)
            }
            self.close()
            return
        }
        
        super.keyDown(with: event)
    }
    
}

struct FloatingWindowContent: View {
    @ObservedObject var windowController: FloatingWindowController
    @State private var transcriptionText = ""
    @State private var isListening = false
    @State private var isPaused = false
    @State private var isTranscribing = false
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: isPaused ? "pause.fill" : (isListening ? "mic.fill" : "mic.slash.fill"))
                    .foregroundColor(isPaused ? .orange : (isListening ? .blue : .red))
                    .font(.title2)
                Text(isPaused ? "Paused" : (isListening ? "Listening..." : "Starting..."))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Show transcription indicator when still processing
                if isTranscribing && isPaused {
                    Image(systemName: "brain.filled.head.profile")
                        .foregroundColor(.yellow)
                        .font(.title3)
                    Text("Processing...")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            
            ScrollView {
                Text(transcriptionText.isEmpty ? "Speak to begin transcription..." : transcriptionText)
                    .font(.body)
                    .foregroundColor(transcriptionText.isEmpty ? .secondary : .primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
            }
            .frame(minHeight: 80, maxHeight: 120)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Press")
                        .foregroundColor(.secondary)
                    Text("↩")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .cornerRadius(4)
                        .font(.caption.monospaced())
                    Text("to send")
                        .foregroundColor(.secondary)
                }
                .font(.caption)
                
                HStack {
                    Text("Press")
                        .foregroundColor(.secondary)
                    Text("SPACE")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .cornerRadius(4)
                        .font(.caption.monospaced())
                    Text(isPaused ? "to resume" : "to pause")
                        .foregroundColor(.secondary)
                }
                .font(.caption)
                
                HStack {
                    Text("Press")
                        .foregroundColor(.secondary)
                    Text("ESC")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .cornerRadius(4)
                        .font(.caption.monospaced())
                    Text("to cancel")
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }
        }
        .padding(24)
        .background(.clear)
        .onAppear {
            startTranscription()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTranscription() {
        Task {
            await windowController.startListening()
            await MainActor.run {
                isListening = true
            }
        }
        
        // Start updating transcription text and pause state
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let newText = windowController.getCurrentTranscription()
            if newText != transcriptionText {
                transcriptionText = newText
            }
            
            let pausedState = windowController.isPaused()
            if pausedState != isPaused {
                isPaused = pausedState
            }
            
            let transcribingState = windowController.isTranscribing()
            if transcribingState != isTranscribing {
                isTranscribing = transcribingState
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
