//
//  CoinHistory.swift
//  Bayliq
//
//  Created by Bhavesh Patel on 26/05/23.
//

import Foundation
struct CoinHistory: Identifiable, Codable,Hashable {
    
    static func == (lhs: CoinHistory, rhs: CoinHistory) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(0)
    }
    
    // MARK: - Variables
    
    let id, symbol, name: String
    let market_data : market_data?
}

struct market_data: Codable {
    let current_price : [String : Double]
}


