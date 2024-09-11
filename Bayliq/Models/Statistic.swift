//
//  Statistic.swift
//  Crypto App
//
//  Created by Nuno Mestre on 8/13/22.
//

import Foundation

struct Statistic: Identifiable {
  
  let id = UUID().uuidString
  let title: String
  let value: String
  let percentageChange: Double?
  
  init(title: String, value: String, percentageChange: Double? = nil) {
    self.title = title
    self.value = value
    self.percentageChange = percentageChange
  }
  
}
