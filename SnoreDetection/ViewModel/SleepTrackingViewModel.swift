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

  private var rollingSamples: [Float] = []
  private var samplesSinceAnalysis = 0
  private var rmsSum: Double = 0
  private var rmsMeasurementCount = 0
  private var lastBannerTime = Date.distantPast
  private let bannerCooldown: TimeInterval = 1
  private let analysisQueue = DispatchQueue(label: "SnoreDetection.EdgeImpulseAnalysis", qos: .userInitiated)
  private let snoreEventTracker = SnoreEventTracker()
  private var completedSnoreEvents: [SnoreEventSummary] = []
  private let modelSampleRate: Double = 48_000
  private let sleepDataManager: SleepDataManager
  private let toastManager: ToastManager

  init(sleepDataManager: SleepDataManager, toastManager: ToastManager) {
    self.sleepDataManager = sleepDataManager
    self.toastManager = toastManager
  }

  @MainActor
  func startTracking(tags: Set<SleepContextTag> = []) {
    print("Dins de startAudioEngine()...")
    currentRMS = 0
    averageRMS = 0
    rmsSum = 0
    rmsMeasurementCount = 0
    rollingSamples.removeAll(keepingCapacity: true)
    samplesSinceAnalysis = 0
    lastBannerTime = .distantPast
    analysisQueue.sync {
      snoreEventTracker.reset()
      completedSnoreEvents.removeAll(keepingCapacity: true)
    }
    startAudioEngine()

    if isTracking {
      sleepDataManager.startNewSession(tags: tags)
    }
  }

  @MainActor
  func stopTracking() {
    let wasTracking = isTracking
    isTracking = false
    stopAudioEngine()

    if wasTracking {
      let events = analysisQueue.sync {
        if let finalEvent = snoreEventTracker.finish(at: Date()) {
          completedSnoreEvents.append(finalEvent)
        }
        let events = completedSnoreEvents
        completedSnoreEvents.removeAll(keepingCapacity: true)
        return events
      }
      events.forEach(sleepDataManager.addSnoreEvent)
      sleepDataManager.endCurrentSession()
    }
  }

  private func startAudioEngine() {
    stopAudioEngine()

    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothHFP])
      try audioSession.setPreferredSampleRate(modelSampleRate)
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
    rmsSum += Double(rms)
    rmsMeasurementCount += 1
    let sessionAverage = Float(rmsSum / Double(rmsMeasurementCount))

    DispatchQueue.main.async {
      self.currentRMS = rms
      self.averageRMS = sessionAverage
    }

    let windowSampleCount = max(Int(sampleRate), 1)
    let hopSampleCount = max(Int(sampleRate / 4), 1)

    rollingSamples.append(contentsOf: samples)
    if rollingSamples.count > windowSampleCount {
      rollingSamples = Array(rollingSamples.suffix(windowSampleCount))
    }

    samplesSinceAnalysis += samples.count
    guard rollingSamples.count == windowSampleCount,
          samplesSinceAnalysis >= hopSampleCount else {
      return
    }

    samplesSinceAnalysis %= hopSampleCount
    let oneSecondWindow = rollingSamples
    let windowRMS = calculateRMS(samples: oneSecondWindow)
    let predictionTime = Date()

    analysisQueue.async { [weak self] in
      guard let self else { return }

      if windowRMS <= self.rmsThreshold {
        self.handlePrediction(
          timestamp: predictionTime,
          snoringProbability: 0,
          rms: windowRMS
        )
        return
      }

      self.runSnoreAnalysis(
        samples: oneSecondWindow,
        rms: windowRMS,
        timestamp: predictionTime
      )
    }
  }

  private func runSnoreAnalysis(
    samples: [Float],
    rms: Float,
    timestamp: Date
  ) {
    let normalizedSamples = resampleForModel(samples)
    guard normalizedSamples.count == Int(modelSampleRate) else {
      print("Nombre de mostres incorrecte per Edge Impulse: \(normalizedSamples.count)")
      return
    }

    // Edge Impulse trained the MFE pipeline with PCM16-scale audio. AVAudioEngine
    // supplies normalized floats, so restore the scale used by the training data.
    var modelSamples = [Float](repeating: 0, count: normalizedSamples.count)
    var pcmScale: Float = 32_768
    vDSP_vsmul(
      normalizedSamples,
      1,
      &pcmScale,
      &modelSamples,
      1,
      vDSP_Length(normalizedSamples.count)
    )

    var lowerBound: Float = -32_768
    var upperBound: Float = 32_767
    vDSP_vclip(
      modelSamples,
      1,
      &lowerBound,
      &upperBound,
      &modelSamples,
      1,
      vDSP_Length(modelSamples.count)
    )

    let peakPCM = modelSamples.reduce(Float.zero) { max($0, abs($1)) }
    print(
      "Inici analisi Edge Impulse de \(modelSamples.count) mostres a 48 kHz, " +
      "pic PCM16=\(peakPCM)"
    )
    let prediction = modelSamples.withUnsafeBufferPointer { buffer in
      EISnoreClassify(buffer.baseAddress, buffer.count)
    }

    guard prediction.success else {
      print("Error Edge Impulse: \(prediction.errorCode)")
      return
    }

    handlePrediction(
      timestamp: timestamp,
      snoringProbability: Double(prediction.snoringConfidence),
      rms: rms
    )

    let isSnore = prediction.isSnore
    let confidence = isSnore
      ? prediction.snoringConfidence
      : prediction.noSnoringConfidence
    let label = isSnore ? "Snoring" : "No Snoring"
    print(
      "Prediccio Edge Impulse: \(label), " +
      "snoring=\(prediction.snoringConfidence), " +
      "noSnoring=\(prediction.noSnoringConfidence)"
    )

    guard Date().timeIntervalSince(lastBannerTime) >= bannerCooldown else {
      return
    }
    lastBannerTime = Date()

    let percentage = Int((confidence * 100).rounded())
    let message = isSnore
      ? "Ronc detectat (\(percentage)% de confiança)"
      : "No sembla un ronc (\(percentage)% de confiança)"

    DispatchQueue.main.async {
      self.toastManager.show(
        message: message,
        type: isSnore ? .error : .success
      )
    }
  }

  private func handlePrediction(
    timestamp: Date,
    snoringProbability: Double,
    rms: Float
  ) {
    let sample = SnorePredictionSample(
      timestamp: timestamp,
      snoringProbability: snoringProbability,
      rms: Double(rms)
    )

    guard let event = snoreEventTracker.consume(sample) else { return }
    completedSnoreEvents.append(event)

    DispatchQueue.main.async { [weak self] in
      self?.persistCompletedSnoreEvents()
    }
  }

  @MainActor
  private func persistCompletedSnoreEvents() {
    let events = analysisQueue.sync {
      let events = completedSnoreEvents
      completedSnoreEvents.removeAll(keepingCapacity: true)
      return events
    }
    events.forEach(sleepDataManager.addSnoreEvent)
  }

  private func resampleForModel(_ samples: [Float]) -> [Float] {
    let targetCount = Int(modelSampleRate)
    guard !samples.isEmpty else { return [] }
    guard samples.count != targetCount else { return samples }
    guard samples.count > 1, targetCount > 1 else {
      return Array(repeating: samples[0], count: targetCount)
    }

    let scale = Double(samples.count - 1) / Double(targetCount - 1)
    return (0..<targetCount).map { targetIndex in
      let sourcePosition = Double(targetIndex) * scale
      let lowerIndex = Int(sourcePosition)
      let upperIndex = min(lowerIndex + 1, samples.count - 1)
      let fraction = Float(sourcePosition - Double(lowerIndex))
      return samples[lowerIndex] +
        (samples[upperIndex] - samples[lowerIndex]) * fraction
    }
  }

  private func calculateRMS(samples: [Float]) -> Float {
    guard !samples.isEmpty else { return 0.0 }
    var sum: Float = 0.0
    vDSP_svesq(samples, 1, &sum, vDSP_Length(samples.count))
    return sqrt(sum / Float(samples.count))
  }
}

class AudioFeatureExtractor {
  private static let fftSize = 2048
  private static let hopSize = 512
  private static let melBandCount = 128
  private static let coefficientCount = 13

  static func calculateZCR(from samples: [Float]) -> Float {
    guard samples.count > 1 else { return 0 }

    let padding = fftSize / 2
    let padded = Array(repeating: samples[0], count: padding) +
      samples +
      Array(repeating: samples[samples.count - 1], count: padding)

    var frameRates: [Float] = []
    var frameStart = 0
    while frameStart + fftSize <= padded.count {
      var crossings = 0
      let frameEnd = frameStart + fftSize
      for index in (frameStart + 1)..<frameEnd {
        if (padded[index - 1] >= 0) != (padded[index] >= 0) {
          crossings += 1
        }
      }
      frameRates.append(Float(crossings) / Float(fftSize))
      frameStart += hopSize
    }

    guard !frameRates.isEmpty else { return 0 }
    return frameRates.reduce(0, +) / Float(frameRates.count)
  }

  static func extractMFCCs(from signal: [Float], sampleRate: Double = 44_100) -> [Float] {
    guard signal.count >= fftSize, sampleRate > 0 else { return [] }

    let paddedSignal = reflectedPadding(signal, amount: fftSize / 2)
    let filters = melFilterBank(sampleRate: sampleRate)
    var window = [Float](repeating: 0, count: fftSize)
    vDSP_hann_window(&window, vDSP_Length(fftSize), 0)

    guard let fftSetup = vDSP_create_fftsetup(
      vDSP_Length(log2(Float(fftSize))),
      FFTRadix(FFT_RADIX2)
    ) else {
      return []
    }
    defer { vDSP_destroy_fftsetup(fftSetup) }

    var melSpectrogram: [[Float]] = []
    var frameStart = 0

    while frameStart + fftSize <= paddedSignal.count {
      let frame = Array(paddedSignal[frameStart..<(frameStart + fftSize)])
      var windowed = [Float](repeating: 0, count: fftSize)
      vDSP_vmul(frame, 1, window, 1, &windowed, 1, vDSP_Length(fftSize))

      let powerSpectrum = powerSpectrum(
        for: windowed,
        fftSetup: fftSetup
      )
      let melPowers = filters.map { filter in
        zip(filter, powerSpectrum).reduce(Float.zero) {
          $0 + $1.0 * $1.1
        }
      }
      melSpectrogram.append(melPowers)
      frameStart += hopSize
    }

    guard !melSpectrogram.isEmpty else { return [] }

    var decibels = melSpectrogram.map { frame in
      frame.map { 10 * log10(max($0, 1e-10)) }
    }
    let maximumDB = decibels.flatMap { $0 }.max() ?? 0
    let floorDB = maximumDB - 80

    for frameIndex in decibels.indices {
      for bandIndex in decibels[frameIndex].indices {
        decibels[frameIndex][bandIndex] = max(
          decibels[frameIndex][bandIndex],
          floorDB
        )
      }
    }

    var coefficientSums = [Float](repeating: 0, count: coefficientCount)
    for frame in decibels {
      let coefficients = dct(frame)
      for index in 0..<coefficientCount {
        coefficientSums[index] += coefficients[index]
      }
    }

    let frameCount = Float(decibels.count)
    return coefficientSums.map { $0 / frameCount }
  }

  private static func reflectedPadding(_ signal: [Float], amount: Int) -> [Float] {
    guard signal.count > amount else { return signal }

    let prefix = signal[1...amount].reversed()
    let suffixStart = signal.count - amount - 1
    let suffix = signal[suffixStart..<(signal.count - 1)].reversed()
    return Array(prefix) + signal + Array(suffix)
  }

  private static func powerSpectrum(
    for frame: [Float],
    fftSetup: FFTSetup
  ) -> [Float] {
    let halfSize = fftSize / 2
    var real = [Float](repeating: 0, count: halfSize)
    var imaginary = [Float](repeating: 0, count: halfSize)

    real.withUnsafeMutableBufferPointer { realPointer in
      imaginary.withUnsafeMutableBufferPointer { imaginaryPointer in
        guard let realBase = realPointer.baseAddress,
              let imaginaryBase = imaginaryPointer.baseAddress else {
          return
        }

        var split = DSPSplitComplex(realp: realBase, imagp: imaginaryBase)
        frame.withUnsafeBufferPointer { framePointer in
          guard let baseAddress = framePointer.baseAddress else { return }
          baseAddress.withMemoryRebound(
            to: DSPComplex.self,
            capacity: halfSize
          ) { complexPointer in
            vDSP_ctoz(
              complexPointer,
              2,
              &split,
              1,
              vDSP_Length(halfSize)
            )
            vDSP_fft_zrip(
              fftSetup,
              &split,
              1,
              vDSP_Length(log2(Float(fftSize))),
              FFTDirection(FFT_FORWARD)
            )
          }
        }
      }
    }

    var power = [Float](repeating: 0, count: halfSize + 1)
    // vDSP's packed real FFT is scaled by two relative to NumPy's
    // rFFT, so power must be divided by four to match librosa.
    let powerScale: Float = 0.25
    power[0] = real[0] * real[0] * powerScale
    power[halfSize] = imaginary[0] * imaginary[0] * powerScale

    if halfSize > 1 {
      for index in 1..<halfSize {
        power[index] = (
          real[index] * real[index] +
          imaginary[index] * imaginary[index]
        ) * powerScale
      }
    }

    return power
  }

  private static func melFilterBank(sampleRate: Double) -> [[Float]] {
    let binCount = fftSize / 2 + 1
    let minimumMel = hzToMel(0)
    let maximumMel = hzToMel(sampleRate / 2)
    let melPoints = (0..<(melBandCount + 2)).map { index in
      minimumMel +
        (maximumMel - minimumMel) *
        Double(index) /
        Double(melBandCount + 1)
    }
    let frequencies = melPoints.map(melToHz)

    return (0..<melBandCount).map { band in
      let lower = frequencies[band]
      let center = frequencies[band + 1]
      let upper = frequencies[band + 2]
      let normalization = 2 / max(upper - lower, .leastNonzeroMagnitude)

      return (0..<binCount).map { bin in
        let frequency = Double(bin) * sampleRate / Double(fftSize)
        let lowerSlope = (frequency - lower) / max(center - lower, .leastNonzeroMagnitude)
        let upperSlope = (upper - frequency) / max(upper - center, .leastNonzeroMagnitude)
        return Float(max(0, min(lowerSlope, upperSlope)) * normalization)
      }
    }
  }

  private static func hzToMel(_ frequency: Double) -> Double {
    if frequency < 1_000 {
      return 3 * frequency / 200
    }
    return 15 + 27 * log(frequency / 1_000) / log(6.4)
  }

  private static func melToHz(_ mel: Double) -> Double {
    if mel < 15 {
      return 200 * mel / 3
    }
    return 1_000 * exp(log(6.4) * (mel - 15) / 27)
  }

  private static func dct(_ values: [Float]) -> [Float] {
    let count = values.count
    return (0..<coefficientCount).map { coefficient in
      let scale = coefficient == 0
        ? sqrt(1 / Float(count))
        : sqrt(2 / Float(count))

      let sum = values.enumerated().reduce(Float.zero) { result, pair in
        let angle =
          Float.pi *
          (Float(pair.offset) + 0.5) *
          Float(coefficient) /
          Float(count)
        return result + pair.element * cos(angle)
      }
      return scale * sum
    }
  }
}
