//
//  InsightsView.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 17/3/25.
//

import SwiftUI
import AVFoundation
import CoreML
import Accelerate

struct InsightsView: View {
  @State private var mfccs: [Float] = []
  @State private var isRecording = false
  @State private var audioRecorder: AVAudioRecorder?
  @State private var recordButtonDisabled = false
  let fileURL: URL = FileManager.default.temporaryDirectory.appendingPathComponent("recording.wav")

  var body: some View {
    VStack(spacing: 20) {
      Text("🎧 Grava i analitza un so")
        .font(.title2)

      Button(action: {
        isRecording ? stopRecording() : startRecording()
      }) {
        Text(isRecording ? "⏹️ Atura" : "🎙️ Inicia gravació")
          .font(.headline)
          .padding()
          .frame(maxWidth: .infinity)
          .background(isRecording ? Color.red : Color.green)
          .foregroundColor(.white)
          .clipShape(Capsule())
      }
      .disabled(recordButtonDisabled)

      if !mfccs.isEmpty {
        VStack(alignment: .leading) {
          Text("📊 MFCCs:")
            .font(.headline)
          ForEach(mfccs.indices, id: \.self) { index in
            Text("MFCC_\(index + 1): \(String(format: "%.5f", mfccs[index]))")
              .monospacedDigit()
          }
        }
        .padding()
      }

      Spacer()
    }
    .padding()
  }

  // MARK: - Gravació
  private func startRecording() {
    let settings: [String: Any] = [
      AVFormatIDKey: Int(kAudioFormatLinearPCM),
      AVSampleRateKey: 16000,
      AVNumberOfChannelsKey: 1,
      AVLinearPCMBitDepthKey: 16,
      AVLinearPCMIsFloatKey: false,
      AVLinearPCMIsBigEndianKey: false
    ]

    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playAndRecord, mode: .default)
      try session.setActive(true)

      audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
      audioRecorder?.record(forDuration: 1.0)
      isRecording = true
      recordButtonDisabled = true

      DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
        stopRecording()
        recordButtonDisabled = false
      }

    } catch {
      print("❌ Error iniciant gravació: \(error)")
    }
  }

  private func stopRecording() {
    audioRecorder?.stop()
    isRecording = false
    processAudio()
  }

  // MARK: - Processa i extreu MFCCs
  private func processAudio() {
    do {
      let file = try AVAudioFile(forReading: fileURL)
      let format = file.processingFormat
      let frameCount = UInt32(file.length)
      guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
        print("❌ No s'ha pogut crear el buffer")
        return
      }
      try file.read(into: buffer)

      guard let floatData = buffer.floatChannelData?[0] else {
        print("❌ No s'han pogut obtenir mostres float")
        return
      }

      let floatArray = Array(UnsafeBufferPointer(start: floatData, count: Int(buffer.frameLength)))
      print("🔊 Samples capturats: \(floatArray.count)")

      //let mfccFeatures = RealTimeSnoreDetector().processSamples(floatArray)
      
      //print("✅ MFCCs: \(mfccFeatures)")

    } catch {
      print("❌ Error llegint l'àudio: \(error)")
    }
  }
}
