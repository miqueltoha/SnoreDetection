//
//  SoundSampleRecorderViewModel.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 15/4/25.
//

import Foundation
import AVFoundation
import Accelerate

class SoundSampleRecorderViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var lastSavedPath: URL?

    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var recordedSamples: [Float] = []
    private var sampleRate: Double = 44100.0

    func startRecording() {
        recordedSamples = []
        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else { return }
        inputNode = engine.inputNode
        guard let input = inputNode else { return }

        let format = input.outputFormat(forBus: 0)
        sampleRate = format.sampleRate

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
            self.recordedSamples.append(contentsOf: samples)
        }

        do {
            try engine.start()
            isRecording = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.stopRecording()
            }
        } catch {
            print("❌ Error iniciant gravació: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isRecording = false
    }

    func saveRecording(label: String) {
        let normalizedSamples = normalize(samples: recordedSamples)
        let mfccs = AudioFeatureExtractor.extractMFCCs(from: normalizedSamples)
        let zcr = AudioFeatureExtractor.calculateZCR(from: normalizedSamples)
        let rms = calculateRMS(samples: normalizedSamples)
        let peak = normalizedSamples.map { abs($0) }.max() ?? 0.0

        guard mfccs.count == 13 else {
            print("❌ Error: MFCCs incomplets")
            return
        }

        let filename = UUID().uuidString + ".csv"
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SoundSamples")
            .appendingPathComponent(label)

        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let fileURL = dir.appendingPathComponent(filename)

        var csv = "zcr,rms,peak," + (1...13).map { "mfcc_\($0)" }.joined(separator: ",") + "\n"
        csv += "\(zcr),\(rms),\(peak)," + mfccs.map { String($0) }.joined(separator: ",") + "\n"

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            lastSavedPath = fileURL
            print("✅ Dades guardades a: \(fileURL.path)")
        } catch {
            print("❌ Error guardant fitxer: \(error.localizedDescription)")
        }
    }

    private func normalize(samples: [Float]) -> [Float] {
        let maxAbs = samples.map { abs($0) }.max() ?? 1.0
        return samples.map { $0 / maxAbs }
    }

    private func calculateRMS(samples: [Float]) -> Float {
        var sum: Float = 0.0
        vDSP_svesq(samples, 1, &sum, vDSP_Length(samples.count))
        return sqrt(sum / Float(samples.count))
    }
}

/*
class AudioFeatureExtractor {
    static func calculateZCR(from samples: [Float]) -> Float {
        guard samples.count > 1 else { return 0.0 }
        var zeroCrossings = 0
        for i in 1..<samples.count {
            if (samples[i - 1] >= 0 && samples[i] < 0) ||
                (samples[i - 1] < 0 && samples[i] >= 0) {
                zeroCrossings += 1
            }
        }
        return Float(zeroCrossings) / Float(samples.count - 1)
    }

    static func extractMFCCs(from signal: [Float]) -> [Float] {
        let fftSize = 1024
        let numCoefficients = 13

        guard signal.count >= fftSize else {
            print("⚠️ No hi ha prou mostres per a FFT")
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
            print("❌ No s'ha pogut crear FFT Setup")
            return []
        }

        real.withUnsafeMutableBufferPointer { realPtr in
            imag.withUnsafeMutableBufferPointer { imagPtr in
                var split = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
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
            print("❌ trimmedLogMagnitudes.count \(trimmedLogMagnitudes.count) != \(dctInputCount)")
            return []
        }

        var dctOutput = [Float](repeating: 0.0, count: dctInputCount)
        if let dctSetup = vDSP.DCT(count: dctInputCount, transformType: .II) {
            dctSetup.transform(trimmedLogMagnitudes, result: &dctOutput)
            return Array(dctOutput.prefix(numCoefficients))
        } else {
            print("❌ Error creant DCT Setup")
            return []
        }
    }
}
*/
