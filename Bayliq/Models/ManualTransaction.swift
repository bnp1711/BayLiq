//
//  ManualTransaction.swift
//  Bayliq
//
//  Created by David Razmadze on 10/24/22.
//

import UIKit

/// Used to format manual transactions in `ManualTransactionView`
struct ManualTransaction: Identifiable, Codable, Equatable,Reorderable {
  var id: String = ""
  var notes: String?
  var quantity: Double = 0.0
  var marketPrice: Double = 0.0
  var symbol: String = ""
  var timestamp: Int = 0
  var exchange: String?
    var purchasedAt = ""
  
  /// Type of transaction: 'bought' or 'sold'
  var type: String
  
  /// New index
  var index: Int?
  var total: Double {
    quantity * marketPrice
  }
  var finalTotal: Double?
    
    typealias OrderElement = String
      var orderElement: OrderElement { exchange ?? "" }
}

// MARK: - ManualTransactionForSorting

struct ManualTransactionForSorting: Identifiable, Codable, Equatable {
  var id: String
  var index: Int
}
