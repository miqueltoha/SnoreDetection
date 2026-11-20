//
//  ToastManager.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 22/3/25.
//

import SwiftUI

class ToastManager: ObservableObject {
  @Published var currentToast: Toast?
  
  func show(message: String, type: ToastType = .info) {
    currentToast = Toast(message: message, type: type)
  }
  
  func hide() {
    currentToast = nil
  }
}
