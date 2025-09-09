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
    @Environment(\.appDelegate) private var appDelegate
    
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
                    
                    if whisperManager.isTranscribing || whisperManager.isRealtimeTranscribing {
                        ProgressView("Transcribing...")
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    
                    if !whisperManager.realtimeText.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Live Transcription:")
                                .font(.headline)
                                .foregroundColor(.blue)
                            Text(whisperManager.realtimeText)
                                .textSelection(.enabled)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                                .animation(.easeInOut(duration: 0.3), value: whisperManager.realtimeText)
                        }
                    }
                    
                    if !whisperManager.transcribedText.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Final Transcription:")
                                .font(.headline)
                                .foregroundColor(.green)
                            Text(whisperManager.transcribedText)
                                .textSelection(.enabled)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    if !whisperManager.transcribedText.isEmpty || !whisperManager.realtimeText.isEmpty {
                        Button("Clear") {
                            whisperManager.clearText()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    Button("Test Floating Window") {
                        appDelegate?.showFloatingWindow()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.purple)
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
            
            audioManager.onStreamingAudioCaptured = { audioData in
                Task {
                    await whisperManager.transcribeRealtime(audioData: audioData)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
