//
//  SleepSessionEntity+Extensions.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 19/3/25.
//

import Foundation

extension SleepSessionEntity {
  var sleepPhasesArray: [SleepPhaseEntity] {
    let set = sleepPhases as? Set<SleepPhaseEntity> ?? []
    return set.sorted { $0.startTime ?? Date() < $1.startTime ?? Date() } // 🔹 Ordenem per startTime
  }
  
  var allSoundEventsArray: [SoundEventEntity] {
    return sleepPhasesArray.flatMap { $0.soundEventsArray }.sorted { $0.startTime ?? Date() < $1.startTime ?? Date() } // 🔹 Extreu tots els sons i els ordena
  }
  
  var snoreEventsArray: [SoundEventEntity] {
    return allSoundEventsArray.filter { $0.eventType == "Snore" }.sorted { $0.startTime ?? Date() < $1.startTime ?? Date() } // 🔹 Filtra només els roncs
  }
}
