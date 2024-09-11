//
//  KeychainManager.swift
//  StockSimulator
//
//  Created by David Razmadze on 9/23/22.
//  Copyright © 2022 David Razmadze. All rights reserved.
//

import UIKit

// Tutorial: https://youtu.be/cQjgBIJtMbw
class KeychainManager {
  
  // MARK: - Keychain Errors
  
  enum KeychainError: Error {
    case duplicateEntry
    case unknown(OSStatus)
  }
  
  // MARK: - Functions
  
  static func save(service: String, account: String, password: Data) throws {
    // service, account, password, class, data
    let query: [String: AnyObject] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service as AnyObject,
      kSecAttrAccount as String: account as AnyObject,
      kSecValueData as String: password as AnyObject
    ]
    
    let status = SecItemAdd(query as CFDictionary, nil)
    
    guard status != errSecDuplicateItem else {
      throw KeychainError.duplicateEntry
    }
    
    guard status == errSecSuccess else {
      throw KeychainError.unknown(status)
    }
    
    print("saved")
    
  }
  
  static func get(service: String, account: String) -> Data? {
    // service, account, class, return data, match limit
    let query: [String: AnyObject] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service as AnyObject,
      kSecAttrAccount as String: account as AnyObject,
      kSecReturnData as String: kCFBooleanTrue,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    
    print("Read status: \(status)")
    
    return result as? Data
  }
  
  static func delete(service: String, account: String) throws {
    let query: [String: AnyObject] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service as AnyObject,
      kSecAttrAccount as String: account as AnyObject,
    ]
    
    let status = SecItemDelete(query as CFDictionary)

    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError.unknown(status)
    }
    
    print("Deleted keychain service for account: \(service)")

  }
  
}

