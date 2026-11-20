//
//  CloudKitManager.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 17/3/25.
//

final class CloudKitManager {
    static let shared = CloudKitManager()

    private init() {}

    func saveSessionToCloud(session: SleepSession) {
        print("CloudKit desactivat per execucio local. Sessio no sincronitzada.")
    }
}
