//
//  Currency.swift
//  Bayliq
//
//  Created by David Razmadze on 12/15/22.
//

import Foundation

struct Currency: Identifiable, Codable {
  var id = UUID()
  var name: String
  var image: String
  var position = CGPoint.zero
  var amount: Double
  var cryptoValue: Double
    var coin : Coin?
}
