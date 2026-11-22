//
//  SleepDataManager.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 17/3/25.
//

import CoreData
import SwiftUI

@MainActor
final class SleepDataManager: ObservableObject {
    @Published private(set) var currentSession: SleepSessionEntity?
    @Published private(set) var currentPhase: SleepPhaseEntity?

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    func startNewSession(tags: Set<SleepContextTag> = []) {
        guard currentSession == nil else { return }

        let startTime = Date()
        let session = SleepSessionEntity(context: context)
        session.id = UUID()
        session.startTime = startTime
        session.sleepQuality = 0
        session.contextTags = tags.map(\.rawValue).sorted().joined(separator: ",")

        let phase = SleepPhaseEntity(context: context)
        phase.id = UUID()
        phase.phaseType = "Monitoring"
        phase.startTime = startTime
        phase.session = session

        currentSession = session
        currentPhase = phase

        if !saveContext() {
            context.rollback()
            currentSession = nil
            currentPhase = nil
        }
    }

    func endCurrentSession() {
        guard let session = currentSession else { return }

        let endTime = Date()
        session.endTime = endTime
        currentPhase?.endTime = endTime

        if saveContext() {
            currentSession = nil
            currentPhase = nil
        }
    }

    func addSleepSession(startTime: Date, endTime: Date, sleepQuality: Double) {
        let session = SleepSessionEntity(context: context)
        session.id = UUID()
        session.startTime = startTime
        session.endTime = endTime
        session.sleepQuality = sleepQuality
        saveContext()
    }

    func addSleepPhase(
        to session: SleepSessionEntity,
        phaseType: String,
        startTime: Date,
        endTime: Date,
        snoringIntensity: Double?,
        oxygenLevel: Double?,
        bodyMovement: Double?,
        heartRate: Double?
    ) {
        let phase = SleepPhaseEntity(context: context)
        phase.id = UUID()
        phase.phaseType = phaseType
        phase.startTime = startTime
        phase.endTime = endTime
        phase.snoringIntensity = snoringIntensity ?? 0
        phase.oxygenLevel = oxygenLevel ?? 0
        phase.bodyMovement = bodyMovement ?? 0
        phase.heartRate = heartRate ?? 0
        phase.session = session
        saveContext()
    }

    func addSoundEvent(
        to phase: SleepPhaseEntity,
        eventType: String,
        startTime: Date,
        endTime: Date,
        intensity: Double,
        frequency: Double?,
        possibleApnea: Bool?
    ) {
        let event = SoundEventEntity(context: context)
        event.id = UUID()
        event.eventType = eventType
        event.startTime = startTime
        event.endTime = endTime
        event.intensity = intensity
        event.duration = endTime.timeIntervalSince(startTime)
        event.frequency = frequency ?? 0
        event.possibleApnea = possibleApnea ?? false
        event.phase = phase
        saveContext()
    }

    func addSnoreEvent(_ summary: SnoreEventSummary) {
        guard let phase = currentPhase else { return }

        let event = SoundEventEntity(context: context)
        event.id = UUID()
        event.eventType = "Snore"
        event.startTime = summary.startTime
        event.endTime = summary.endTime
        event.duration = summary.duration
        event.intensity = summary.maximumRMS
        event.frequency = 0
        event.possibleApnea = false
        event.averageConfidence = summary.averageConfidence
        event.maximumConfidence = summary.maximumConfidence
        event.averageRMS = summary.averageRMS
        event.maximumRMS = summary.maximumRMS
        event.predictionCount = Int32(summary.predictionCount)
        event.phase = phase
        saveContext()
    }

    func fetchSleepSessions() -> [SleepSessionEntity] {
        let request: NSFetchRequest<SleepSessionEntity> = SleepSessionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SleepSessionEntity.startTime, ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error recuperant sessions de son: \(error.localizedDescription)")
            return []
        }
    }

    func deleteSleepSession(_ session: SleepSessionEntity) {
        context.delete(session)
        saveContext()
    }

    @discardableResult
    private func saveContext() -> Bool {
        guard context.hasChanges else { return true }

        do {
            try context.save()
            return true
        } catch {
            print("Error guardant dades de son: \(error.localizedDescription)")
            return false
        }
    }
}
