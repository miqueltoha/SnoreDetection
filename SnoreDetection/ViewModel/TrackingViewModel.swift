//
//  TrackingViewModel.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 22/3/25.
//

import Foundation
import Combine

class TrackingViewModel: ObservableObject {
  // 🔁 Control per aturar el tracking des d'altres esdeveniments (com el logout)
  @Published var shouldStopTracking: Bool = false
  
  // 🔐 Login info (es pot sincronitzar amb AppState si cal)
  @Published var isUserLoggedIn: Bool = true
  
  // 🔔 Mecanisme per notificar esdeveniments a altres vistes si cal
  private var cancellables = Set<AnyCancellable>()
  
  init() {
    setupBindings()
  }
  
  private func setupBindings() {
    // Exemple: si l'usuari tanca la sessió, notifiquem que cal aturar el tracking
    $isUserLoggedIn
      .dropFirst() // Per evitar que dispari a l’inici
      .sink { [weak self] loggedIn in
        if !loggedIn {
          self?.shouldStopTracking = true
        }
      }
      .store(in: &cancellables)
  }
  
  /// 🔄 Pots cridar aquesta funció quan facis logout
  func logoutUser() {
    isUserLoggedIn = false
  }
  
  /// 🧹 Reinicia l'estat (per exemple, després d'haver aturat la sessió)
  func resetState() {
    shouldStopTracking = false
  }
}
