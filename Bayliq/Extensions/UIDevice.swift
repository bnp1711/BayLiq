//
//  UIDevice.swift
//  Bayliq
//
//  Created by David Razmadze on 10/23/22.
//

import SwiftUI

extension UIDevice {
  static var isIPad: Bool {
    UIDevice.current.userInterfaceIdiom == .pad
  }
  
  static var isIPhone: Bool {
    UIDevice.current.userInterfaceIdiom == .phone
  }
}
extension URLCache {
    
    static let imageCache = URLCache(memoryCapacity: 512*1000*1000, diskCapacity: 10*1000*1000*1000)
}
