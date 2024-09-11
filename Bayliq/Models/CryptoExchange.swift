//
//  CryptoExchange.swift
//  Bayliq
//
//  Created by Bhavesh patel on 12/5/22.
//

import UIKit

/// Used to format no transactions in `NoTransaction`
struct CryptoExchange: Identifiable, Codable, Equatable {
  var id = UUID()
  var iconURL: String = ""
  var name: String = ""
  var websiteURL: String = ""
  
}

extension Encodable {
  func asDictionary() throws -> [String: Any] {
    let data = try JSONEncoder().encode(self)
    guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
      throw NSError()
    }
    return dictionary
  }
}
