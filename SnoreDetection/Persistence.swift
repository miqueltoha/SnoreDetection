//
//  Persistence.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 17/3/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        let newSession = SleepSessionEntity(context: viewContext)
        newSession.id = UUID()
        newSession.startTime = Date()
        newSession.endTime = Date().addingTimeInterval(8 * 60 * 60)
        newSession.sleepQuality = 0.0

        do {
            try viewContext.save()
        } catch {
            print("Error creant dades de previsualitzacio: \(error.localizedDescription)")
        }

        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SnoreDetection")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        container.loadPersistentStores { _, error in
            if let error {
                print("Error carregant Core Data: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
