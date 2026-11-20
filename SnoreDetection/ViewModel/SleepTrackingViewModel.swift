//
//  SleepTrackingViewModel.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 21/3/25.
//

import Foundation
import AVFoundation
import Accelerate
import Combine
import CoreML

class SleepTrackingViewModel: ObservableObject {
  @Published var isTracking = false
  @Published var currentRMS: Float = 0.0
  @Published var averageRMS: Float = 0.0

  private var audioEngine: AVAudioEngine?
  private var inputNode: AVAudioInputNode?
  private var hasInstalledTap = false
  private var cancellables = Set<AnyCancellable>()
  private var sampleRate: Double = 44100.0
  private let rmsThreshold: Float = 0.003

  private var recordedSamples: [Float] = []
  private var isRecording = false
  private var recordTimer: Timer?
  private let model: SnoreBinary_NoRMS?

  init() {
    do {
      model = try SnoreBinary_NoRMS(configuration: MLModelConfiguration())
    } catch {
      model = nil
      print("Error carregant el model Core ML: \(error.localizedDescription)")
    }
  }

  func startTracking() {
    print("Dins de startAudioEngine()...")
    startAudioEngine()
  }

  func stopTracking() {
    isTracking = false
    stopAudioEngine()
  }

  private func startAudioEngine() {
    stopAudioEngine()

    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothHFP])
      try audioSession.setActive(true)
    } catch {
      isTracking = false
      print("Error configurant la sessio d'audio: \(error.localizedDescription)")
      return
    }

    audioEngine = AVAudioEngine()
    guard let engine = audioEngine else { return }
    inputNode = engine.inputNode
    guard let input = inputNode else { return }

    let format = input.outputFormat(forBus: 0)
    guard format.sampleRate > 0, format.channelCount > 0 else {
      audioEngine = nil
      inputNode = nil
      isTracking = false
      print("Format d'entrada d'audio invalid: \(format)")
      return
    }

    sampleRate = format.sampleRate

    input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
      self.processAudioBuffer(buffer)
    }
    hasInstalledTap = true

    do {
      try engine.start()
      isTracking = true
      print("Monitoritzacio iniciada")
    } catch {
      if hasInstalledTap {
        input.removeTap(onBus: 0)
        hasInstalledTap = false
      }
      audioEngine = nil
      inputNode = nil
      isTracking = false
      print("Error engegant l'audio: \(error.localizedDescription)")
    }
  }

  private func stopAudioEngine() {
    if hasInstalledTap, let inputNode {
      inputNode.removeTap(onBus: 0)
      hasInstalledTap = false
    }

    audioEngine?.stop()
    audioEngine = nil
    inputNode = nil
    print("Monitoritzacio aturada")
  }

  private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
    guard let channelData = buffer.floatChannelData?[0] else { return }
    let frameLength = Int(buffer.frameLength)
    let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))

    let rms = calculateRMS(samples: samples)
    DispatchQueue.main.async {
      self.currentRMS = rms
      self.averageRMS = self.averageRMS == 0 ? rms : (self.averageRMS * 0.9 + rms * 0.1)
    }

    if rms > rmsThreshold && isTracking && !isRecording {
      print("Soroll detectat. Gravarem 1 segon...")
      isRecording = true
      recordedSamples = []
      recordedSamples.append(contentsOf: samples)

      recordTimer?.invalidate()
      DispatchQueue.main.async {
        self.recordTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
          print("Timer executat")
          print("Samples acumulats: \(self.recordedSamples.count)")
          let oneSecondBuffer = self.recordedSamples
          self.recordedSamples = []
          self.runSnoreAnalysis(samples: oneSecondBuffer)
          self.isRecording = false
        }
      }
    } else if isRecording {
      print("Afegint samples mentre gravem. Total actual: \(recordedSamples.count)")
      recordedSamples.append(contentsOf: samples)
    }
  }

  private func runSnoreAnalysis(samples: [Float]) {
    guard let model else {
      print("Model Core ML no disponible. S'omet l'analisi de roncs.")
      return
    }

    print("Inici analisi de \(samples.count) mostres")
    let mfccs = AudioFeatureExtractor.extractMFCCs(from: samples)
    print("MFCCs:", mfccs)

    let zcr = AudioFeatureExtractor.calculateZCR(from: samples)
    print("ZCR:", zcr)

    if mfccs.count == 13 {
      do {
        let prediction = try model.prediction(
          zcr: Double(zcr),
          mfcc_1: Double(mfccs[0]),
          mfcc_2: Double(mfccs[1]),
          mfcc_3: Double(mfccs[2]),
          mfcc_4: Double(mfccs[3]),
          mfcc_5: Double(mfccs[4]),
          mfcc_6: Double(mfccs[5]),
          mfcc_7: Double(mfccs[6]),
          mfcc_8: Double(mfccs[7]),
          mfcc_9: Double(mfccs[8]),
          mfcc_10: Double(mfccs[9]),
          mfcc_11: Double(mfccs[10]),
          mfcc_12: Double(mfccs[11]),
          mfcc_13: Double(mfccs[12])
        )

        let label = prediction.classLabel
        let confidence = prediction.classProbability[label] ?? 0.0
        print("Prediccio: \(label) amb confianca: \(confidence)")

        if label == "snore" {
          DispatchQueue.main.async {
            NotificationCenter.default.post(name: .showToast, object: "Ronc detectat")
          }
        }
      } catch {
        print("Error durant la prediccio: \(error.localizedDescription)")
      }
    }
  }

  private func calculateRMS(samples: [Float]) -> Float {
    guard !samples.isEmpty else { return 0.0 }
    var sum: Float = 0.0
    vDSP_svesq(samples, 1, &sum, vDSP_Length(samples.count))
    return sqrt(sum / Float(samples.count))
  }
}

extension Notification.Name {
  static let showToast = Notification.Name("showToast")
}

class AudioFeatureExtractor {
  static func calculateZCR(from samples: [Float]) -> Float {
    let safeSamples = Array(samples)
    guard safeSamples.count > 1 else { return 0.0 }
    var zeroCrossings = 0
    for i in 1..<safeSamples.count {
      if (safeSamples[i - 1] >= 0 && safeSamples[i] < 0) ||
         (safeSamples[i - 1] < 0 && safeSamples[i] >= 0) {
        zeroCrossings += 1
      }
    }
    return Float(zeroCrossings) / Float(safeSamples.count - 1)
  }

  static func extractMFCCs(from signal: [Float]) -> [Float] {
    let fftSize = 1024
    let numCoefficients = 13

    guard signal.count >= fftSize else {
      print("No hi ha prou mostres per a FFT")
      return []
    }

    var window = [Float](repeating: 0.0, count: fftSize)
    vDSP_hamm_window(&window, vDSP_Length(fftSize), 0)

    let signalSegment = Array(signal.prefix(fftSize))
    var windowed = [Float](repeating: 0.0, count: fftSize)
    vDSP_vmul(signalSegment, 1, window, 1, &windowed, 1, vDSP_Length(fftSize))

    var real = [Float](repeating: 0.0, count: fftSize / 2)
    var imag = [Float](repeating: 0.0, count: fftSize / 2)
    var magnitudes = [Float](repeating: 0.0, count: fftSize / 2)

    guard let fftSetup = vDSP_create_fftsetup(vDSP_Length(log2(Float(fftSize))), FFTRadix(FFT_RADIX2)) else {
      print("No s'ha pogut crear FFT Setup")
      return []
    }

    real.withUnsafeMutableBufferPointer { realPtr in
      imag.withUnsafeMutableBufferPointer { imagPtr in
        guard let realBaseAddress = realPtr.baseAddress,
              let imagBaseAddress = imagPtr.baseAddress else {
          return
        }

        var split = DSPSplitComplex(realp: realBaseAddress, imagp: imagBaseAddress)
        windowed.withUnsafeBufferPointer { ptr in
          guard let baseAddress = ptr.baseAddress else { return }
          baseAddress.withMemoryRebound(to: DSPComplex.self, capacity: fftSize) { complexPtr in
            vDSP_ctoz(complexPtr, 2, &split, 1, vDSP_Length(fftSize / 2))
            vDSP_fft_zrip(fftSetup, &split, 1, vDSP_Length(log2(Float(fftSize))), FFTDirection(FFT_FORWARD))
            vDSP_zvmags(&split, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))
          }
        }
      }
    }

    vDSP_destroy_fftsetup(fftSetup)

    var logMagnitudes = [Float](repeating: 0.0, count: fftSize / 2)
    var one: Float = 1.0
    vDSP_vsmsa(magnitudes, 1, &one, &one, &logMagnitudes, 1, vDSP_Length(fftSize / 2))
    vvlogf(&logMagnitudes, logMagnitudes, [Int32(fftSize / 2)])

    let dctInputCount = 128
    let trimmedLogMagnitudes = Array(logMagnitudes.prefix(dctInputCount))

    guard trimmedLogMagnitudes.count == dctInputCount else {
      print("trimmedLogMagnitudes.count \(trimmedLogMagnitudes.count) != \(dctInputCount)")
      return []
    }

    var dctOutput = [Float](repeating: 0.0, count: dctInputCount)
    if let dctSetup = vDSP.DCT(count: dctInputCount, transformType: .II) {
      dctSetup.transform(trimmedLogMagnitudes, result: &dctOutput)
      let mfccs = Array(dctOutput.prefix(numCoefficients))
      return mfccs
    } else {
      print("Error creant DCT Setup")
      return []
    }
  }
}
