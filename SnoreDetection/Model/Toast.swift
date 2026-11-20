//
//  Toast.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 22/3/25.
//

import Foundation

enum ToastType {
  case success, error, info
}

struct Toast: Identifiable {
  let id = UUID()
  let message: String
  let type: ToastType
}
