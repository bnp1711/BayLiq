//
//  UIApplication.swift
//  Bayliq
//
//  Created by David Razmadze on 10/23/22.
//

import Foundation
import SwiftUI

extension UIApplication {
  func endEditing() {
    sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}

extension UIScreen{
  static let screenWidth = UIScreen.main.bounds.size.width
  static let screenHeight = UIScreen.main.bounds.size.height
  static let screenSize = UIScreen.main.bounds.size
}
