//
//  ExchangeCurrency.swift
//  Bayliq
//
//  Created by Natanael Jop on 24/11/2022.
//

import Foundation

struct ExchangeResponse: Decodable {
  var rates: [String: Double]
}

struct ExchangeSymbolResponse: Decodable {
  var currencies: [Symbol]
}

struct Symbol: Decodable {
  var currency: String?
  var abbreviation: String?
  var symbol: String?
}
