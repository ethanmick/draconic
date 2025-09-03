//
//  ContentView.swift
//  draconic
//
//  Created by Ethan Mick on 9/3/25.
//

import SwiftUI

struct ContentView: View {
    @State private var whisperManager = WhisperManager()
    @State private var audioManager = AudioCaptureManager()
    @State private var hasPermission = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Draconic Dictation")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if !hasPermission {
                VStack {
                    Text("Microphone permission required")
                        .foregroundColor(.secondary)
                    Button("Grant Permission") {
                        Task {
                            hasPermission = await audioManager.requestMicrophonePermission()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                VStack {
                    Button(audioManager.isRecording ? "Stop Recording" : "Start Recording") {
                        if audioManager.isRecording {
                            audioManager.stopRecording()
                        } else {
                            audioManager.startRecording()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundColor(audioManager.isRecording ? .red : .blue)
                    
                    if whisperManager.isTranscribing {
                        ProgressView("Transcribing...")
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    
                    if !whisperManager.transcribedText.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Transcribed Text:")
                                .font(.headline)
                            Text(whisperManager.transcribedText)
                                .textSelection(.enabled)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    if !whisperManager.transcribedText.isEmpty {
                        Button("Clear") {
                            whisperManager.clearText()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            Task {
                hasPermission = await audioManager.requestMicrophonePermission()
            }
            
            audioManager.onAudioCaptured = { audioData in
                Task {
                    await whisperManager.transcribe(audioData: audioData)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
