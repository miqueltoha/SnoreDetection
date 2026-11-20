//
//  SleepSessionDetailView.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 20/3/25.
//

import SwiftUI

struct SleepSessionDetailView: View {
  var session: SleepSessionEntity
  
  @FetchRequest var sleepPhases: FetchedResults<SleepPhaseEntity>
  
  init(session: SleepSessionEntity) {
    self.session = session
    _sleepPhases = FetchRequest(
      entity: SleepPhaseEntity.entity(),
      sortDescriptors: [NSSortDescriptor(keyPath: \SleepPhaseEntity.startTime, ascending: true)],
      predicate: NSPredicate(format: "session == %@", session)
    )
  }
  
  var body: some View {
    VStack {
      Text("Detalls de la Sessió")
        .font(.largeTitle)
        .padding()
      
      Text("Data: \(session.startTime ?? Date(), formatter: dateFormatter)")
        .font(.headline)
      
      Text("Qualitat del son: \(session.sleepQuality, specifier: "%.2f")")
        .font(.subheadline)
        .padding(.bottom, 10)
      
      List(sleepPhases) { phase in
        VStack(alignment: .leading) {
          Text("Fase: \(phase.phaseType ?? "Desconegut")")
            .font(.headline)
          Text("Inici: \(phase.startTime ?? Date(), formatter: dateFormatter)")
            .font(.subheadline)
            .foregroundColor(.gray)
        }
      }
    }
    .padding()
  }
}

private let dateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateStyle = .medium
  formatter.timeStyle = .short
  return formatter
}()
