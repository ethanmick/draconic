//
//  AudioCaptureManager.swift
//  draconic
//
//  Created by Ethan Mick on 9/3/25.
//

import Foundation
import AVFoundation
import SwiftUI

@Observable
class AudioCaptureManager: NSObject {
    private var audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode?
    private var audioBuffer = Data()
    
    var isRecording = false
    var onAudioCaptured: ((Data) -> Void)?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        audioBuffer = Data()
        inputNode = audioEngine.inputNode
        
        let inputFormat = inputNode!.outputFormat(forBus: 0)
        let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, 
                                          sampleRate: 16000, 
                                          channels: 1, 
                                          interleaved: false)!
        
        let converter = AVAudioConverter(from: inputFormat, to: recordingFormat)
        
        inputNode!.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            let convertedBuffer = AVAudioPCMBuffer(pcmFormat: recordingFormat, frameCapacity: AVAudioFrameCount(recordingFormat.sampleRate * Double(buffer.frameLength) / inputFormat.sampleRate))!
            
            var error: NSError?
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = AVAudioConverterInputStatus.haveData
                return buffer
            }
            
            converter?.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
            
            if let channelData = convertedBuffer.int16ChannelData?[0] {
                let data = Data(bytes: channelData, count: Int(convertedBuffer.frameLength * 2))
                
                DispatchQueue.main.async {
                    self.audioBuffer.append(data)
                }
            }
        }
        
        do {
            try audioEngine.start()
            isRecording = true
            print("Started recording")
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine.stop()
        inputNode?.removeTap(onBus: 0)
        isRecording = false
        
        print("Stopped recording, captured \(audioBuffer.count) bytes")
        
        if !audioBuffer.isEmpty {
            onAudioCaptured?(createWAVData(from: audioBuffer))
        }
        
        audioBuffer = Data()
    }
    
    private func createWAVData(from pcmData: Data) -> Data {
        var wavData = Data()
        
        let sampleRate: UInt32 = 16000
        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let byteRate = sampleRate * UInt32(channels) * UInt32(bitsPerSample) / 8
        let blockAlign = channels * bitsPerSample / 8
        let dataSize = UInt32(pcmData.count)
        let fileSize = 36 + dataSize
        
        wavData.append("RIFF".data(using: .ascii)!)
        wavData.append(Data(bytes: &fileSize.littleEndian, count: 4))
        wavData.append("WAVE".data(using: .ascii)!)
        wavData.append("fmt ".data(using: .ascii)!)
        
        var fmtChunkSize: UInt32 = 16
        wavData.append(Data(bytes: &fmtChunkSize.littleEndian, count: 4))
        
        var audioFormat: UInt16 = 1
        wavData.append(Data(bytes: &audioFormat.littleEndian, count: 2))
        wavData.append(Data(bytes: &channels.littleEndian, count: 2))
        wavData.append(Data(bytes: &sampleRate.littleEndian, count: 4))
        wavData.append(Data(bytes: &byteRate.littleEndian, count: 4))
        wavData.append(Data(bytes: &blockAlign.littleEndian, count: 2))
        wavData.append(Data(bytes: &bitsPerSample.littleEndian, count: 2))
        
        wavData.append("data".data(using: .ascii)!)
        wavData.append(Data(bytes: &dataSize.littleEndian, count: 4))
        wavData.append(pcmData)
        
        return wavData
    }
}