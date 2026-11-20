//
//  PushNotificationManager.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 17/3/25.
//

import SwiftUI
import UserNotifications

@MainActor
class PushNotificationManager: ObservableObject {
    @Published var deviceToken: String?

    init() {}

    func requestLocalNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Error demanant permis de notificacions: \(error.localizedDescription)")
                return
            }

            if granted {
                print("Permis concedit per notificacions locals")
            } else {
                print("Permis denegat per notificacions locals")
            }
        }
    }

    func updateDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02x", $0) }.joined()
        deviceToken = tokenString
        print("Token APNs obtingut: \(tokenString)")
    }
}
