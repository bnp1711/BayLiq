//
//  NoTransaction.swift
//  Bayliq
//
//  Created by Bhavesh patel on 11/30/22.
//

import UIKit

/// Used to format no transactions in `NoTransaction`
struct NoTransaction: Identifiable, Codable, Equatable {
  let id = UUID()
  var iconURL: String = ""
  var name: String = ""
  var websiteURL: String = ""

}
