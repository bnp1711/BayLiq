 //
//  CurrencyFormatter.swift
//  Bayliq
//
//  Created by Natanael Jop on 25/11/2022.
//

import Foundation
import SwiftUI

class NumberHelper {
  
  class func formatPoints(num: Double) -> String {
    let thousandNum = num / 1000
    let millionNum = num / 1000000
    let billionNum = num / 1000000000
    let trillionNum = num / 1000000000000
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .decimal
    
    // Millions
    if num > 1000000 && num < 1000000000 {
      if floor(millionNum) == millionNum {
        return("\(Int(thousandNum))k")
      }
      return ("\(numberFormatter.string(from: NSNumber(value:millionNum.roundToPlaces(places: 2))) ?? "")M")
    }
    // Billions
    if num > 1000000000 && num < 1000000000000 {
      if floor(millionNum) == billionNum {
        return("\(Int(thousandNum))M")
      }
      return ("\(numberFormatter.string(from: NSNumber(value:billionNum.roundToPlaces(places: 2))) ?? "")B")
    }
    // Trillions
    if num > 1000000000000 {
      if floor(trillionNum) == trillionNum {
        return("\(Int(billionNum))B")
      }
      return ("\(numberFormatter.string(from: NSNumber(value:trillionNum.roundToPlaces(places: 2))) ?? "")T")
    } else {
      if floor(num) == num {
        return ("\(numberFormatter.string(from: NSNumber(value:num.roundToPlaces(places: 2))) ?? "")")
      }
      return ("\(numberFormatter.string(from: NSNumber(value:num.roundToPlaces(places: 2))) ?? "")")
    }
    
  }
  
}
