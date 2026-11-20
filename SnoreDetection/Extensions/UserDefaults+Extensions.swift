//
//  UserDefaults+Extensions.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 19/3/25.
//

import Foundation

extension UserDefaults {
  private enum Keys {
    static let userId = "userId"
    static let userName = "userName"
    static let userEmail = "userEmail"
    static let isLoggedIn = "isLoggedIn"
  }
  
  var userId: String? {
    get { string(forKey: Keys.userId) }
    set { set(newValue, forKey: Keys.userId) }
  }
  
  var userName: String? {
    get { string(forKey: Keys.userName) }
    set { set(newValue, forKey: Keys.userName) }
  }
  
  var userEmail: String? {
    get { string(forKey: Keys.userEmail) }
    set { set(newValue, forKey: Keys.userEmail) }
  }
  
  var isLoggedIn: Bool {
    get { bool(forKey: Keys.isLoggedIn) }
    set { set(newValue, forKey: Keys.isLoggedIn) }
  }
  
  func clearUserData() {
    removeObject(forKey: Keys.userId)
    removeObject(forKey: Keys.userName)
    removeObject(forKey: Keys.userEmail)
    removeObject(forKey: Keys.isLoggedIn)
  }
}
