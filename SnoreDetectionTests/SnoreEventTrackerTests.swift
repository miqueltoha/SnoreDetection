import Foundation
import Testing
@testable import SnoreDetection

struct SnoreEventTrackerTests {
    private let start = Date(timeIntervalSince1970: 1_000)

    @Test
    func isolatedPositiveDoesNotCreateEvent() {
        let tracker = SnoreEventTracker()

        #expect(tracker.consume(sample(at: 0, probability: 0.8, rms: 0.1)) == nil)
        #expect(tracker.consume(sample(at: 0.25, probability: 0.2, rms: 0.02)) == nil)
        #expect(tracker.finish(at: start.addingTimeInterval(1)) == nil)
    }

    @Test
    func consecutivePredictionsCreateAndCloseEvent() throws {
        let tracker = SnoreEventTracker()

        #expect(tracker.consume(sample(at: 0, probability: 0.7, rms: 0.10)) == nil)
        #expect(tracker.consume(sample(at: 0.25, probability: 0.9, rms: 0.30)) == nil)
        #expect(tracker.consume(sample(at: 0.50, probability: 0.8, rms: 0.20)) == nil)
        #expect(tracker.consume(sample(at: 0.75, probability: 0.1, rms: 0.01)) == nil)
        #expect(tracker.consume(sample(at: 1.00, probability: 0.1, rms: 0.01)) == nil)

        let event = try #require(
            tracker.consume(sample(at: 1.25, probability: 0.1, rms: 0.01))
        )

        #expect(event.startTime == start)
        #expect(event.endTime == start.addingTimeInterval(0.75))
        #expect(event.duration == 0.75)
        #expect(event.predictionCount == 3)
        #expect(abs(event.averageConfidence - 0.8) < 0.000_001)
        #expect(event.maximumConfidence == 0.9)
        #expect(abs(event.averageRMS - 0.2) < 0.000_001)
        #expect(event.maximumRMS == 0.3)
    }

    @Test
    func finishFlushesActiveEvent() throws {
        let tracker = SnoreEventTracker()

        #expect(tracker.consume(sample(at: 0, probability: 0.7, rms: 0.10)) == nil)
        #expect(tracker.consume(sample(at: 0.25, probability: 0.9, rms: 0.30)) == nil)

        let event = try #require(
            tracker.finish(at: start.addingTimeInterval(0.4))
        )

        #expect(event.startTime == start)
        #expect(event.endTime == start.addingTimeInterval(0.4))
        #expect(event.predictionCount == 2)
        #expect(tracker.finish(at: start.addingTimeInterval(1)) == nil)
    }

    private func sample(
        at offset: TimeInterval,
        probability: Double,
        rms: Double
    ) -> SnorePredictionSample {
        SnorePredictionSample(
            timestamp: start.addingTimeInterval(offset),
            snoringProbability: probability,
            rms: rms
        )
    }
}
