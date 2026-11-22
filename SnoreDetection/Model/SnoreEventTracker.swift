import Foundation

struct SnorePredictionSample: Equatable, Sendable {
    let timestamp: Date
    let snoringProbability: Double
    let rms: Double
}

struct SnoreEventSummary: Equatable, Sendable {
    let startTime: Date
    let endTime: Date
    let averageConfidence: Double
    let maximumConfidence: Double
    let averageRMS: Double
    let maximumRMS: Double
    let predictionCount: Int

    var duration: TimeInterval {
        max(0, endTime.timeIntervalSince(startTime))
    }
}

final class SnoreEventTracker {
    private let positiveThreshold: Double
    private let positivesToStart: Int
    private let negativesToEnd: Int
    private let predictionInterval: TimeInterval

    private var pendingPositiveSamples: [SnorePredictionSample] = []
    private var activeSamples: [SnorePredictionSample] = []
    private var consecutiveNegatives = 0
    private var lastPositiveTime: Date?

    init(
        positiveThreshold: Double = 0.6,
        positivesToStart: Int = 2,
        negativesToEnd: Int = 3,
        predictionInterval: TimeInterval = 0.25
    ) {
        self.positiveThreshold = positiveThreshold
        self.positivesToStart = positivesToStart
        self.negativesToEnd = negativesToEnd
        self.predictionInterval = predictionInterval
    }

    func consume(_ sample: SnorePredictionSample) -> SnoreEventSummary? {
        if sample.snoringProbability >= positiveThreshold {
            return consumePositive(sample)
        }

        return consumeNegative()
    }

    func finish(at timestamp: Date = Date()) -> SnoreEventSummary? {
        guard !activeSamples.isEmpty else {
            reset()
            return nil
        }

        let naturalEnd = (lastPositiveTime ?? timestamp)
            .addingTimeInterval(predictionInterval)
        let endTime = min(timestamp, naturalEnd)
        let summary = makeSummary(endTime: endTime)
        reset()
        return summary
    }

    func reset() {
        pendingPositiveSamples.removeAll(keepingCapacity: true)
        activeSamples.removeAll(keepingCapacity: true)
        consecutiveNegatives = 0
        lastPositiveTime = nil
    }

    private func consumePositive(
        _ sample: SnorePredictionSample
    ) -> SnoreEventSummary? {
        consecutiveNegatives = 0
        lastPositiveTime = sample.timestamp

        if activeSamples.isEmpty {
            pendingPositiveSamples.append(sample)
            if pendingPositiveSamples.count >= positivesToStart {
                activeSamples = pendingPositiveSamples
                pendingPositiveSamples.removeAll(keepingCapacity: true)
            }
        } else {
            activeSamples.append(sample)
        }

        return nil
    }

    private func consumeNegative() -> SnoreEventSummary? {
        guard !activeSamples.isEmpty else {
            pendingPositiveSamples.removeAll(keepingCapacity: true)
            return nil
        }

        consecutiveNegatives += 1
        guard consecutiveNegatives >= negativesToEnd else { return nil }

        guard let fallbackEndTime = activeSamples.last?.timestamp else { return nil }
        let endTime = (lastPositiveTime ?? fallbackEndTime)
            .addingTimeInterval(predictionInterval)
        let summary = makeSummary(endTime: endTime)
        reset()
        return summary
    }

    private func makeSummary(endTime: Date) -> SnoreEventSummary {
        let confidenceSum = activeSamples.reduce(0.0) {
            $0 + $1.snoringProbability
        }
        let rmsSum = activeSamples.reduce(0.0) { $0 + $1.rms }
        let count = activeSamples.count

        return SnoreEventSummary(
            startTime: activeSamples[0].timestamp,
            endTime: endTime,
            averageConfidence: confidenceSum / Double(count),
            maximumConfidence: activeSamples.map(\.snoringProbability).max() ?? 0,
            averageRMS: rmsSum / Double(count),
            maximumRMS: activeSamples.map(\.rms).max() ?? 0,
            predictionCount: count
        )
    }
}
