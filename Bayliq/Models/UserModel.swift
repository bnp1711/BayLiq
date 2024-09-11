//
//  UserModel.swift
//  Bayliq
//
//  Created by Nuno Mestre on 7/30/22.
//

import Foundation

struct BayliqUser: Identifiable {
  var id: String
  var username: String
  var email: String
  var memberSince: Int
}
