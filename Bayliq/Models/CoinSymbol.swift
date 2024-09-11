//
//  CoinSymbol.swift
//  Bayliq
//
//  Created by Dmitry Magadya on 1.07.24.
//

import Foundation
struct CoinSymbol: Codable {
  let id, symbol, name: String?
 
  enum CodingKeys: String, CodingKey {
    case id = "id"
    case symbol = "symbol"
    case name = "name"
  }
  
}
