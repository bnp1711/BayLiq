//
//  HapticManager.swift
//  Crypto App
//
//  Created by Nuno Mestre on 8/13/22.
//

import SwiftUI

class HapticManager {
  
  static private let generator = UINotificationFeedbackGenerator()
  
  static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
    generator.notificationOccurred(type)
  }
  
}
