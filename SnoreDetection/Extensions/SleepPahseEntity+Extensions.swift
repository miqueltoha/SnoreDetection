//
//  SleepPahseEntity+Extensions.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 19/3/25.
//

import Foundation

extension SleepPhaseEntity {
  var soundEventsArray: [SoundEventEntity] {
    let set = soundEvents as? Set<SoundEventEntity> ?? []
    return set.sorted { $0.startTime ?? Date() < $1.startTime ?? Date() } // 🔹 Ordenem per startTime
  }
  
  /// 🔹 Converteix la cadena `backgroundNoiseLevels` en un array de `Double`
  var backgroundNoiseArray: [Double] {
    get {
      guard let noiseString = backgroundNoiseLevels else { return [] }
      return noiseString.split(separator: ",").compactMap { Double($0) }
    }
    set {
      backgroundNoiseLevels = newValue.map { String($0) }.joined(separator: ",")
    }
  }
  
  /// 🔹 Calcula la mitjana del soroll de fons durant la fase
  var averageBackgroundNoise: Double {
    let noiseValues = backgroundNoiseArray
    return noiseValues.isEmpty ? 0.0 : noiseValues.reduce(0, +) / Double(noiseValues.count)
  }
  
  /// 🔹 Afegeix un nou valor de soroll de fons a la llista
  func addBackgroundNoiseLevel(_ level: Double) {
    var noiseArray = backgroundNoiseArray
    noiseArray.append(level)
    backgroundNoiseArray = noiseArray // 🔹 Guarda el nou array a CoreData
  }
}
