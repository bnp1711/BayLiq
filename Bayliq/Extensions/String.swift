//
//  String.swift
//  Bayliq
//
//  Created by David Razmadze on 10/23/22.
//

import Foundation

extension String {
  
  var removingHTMLOccurances: String {
    return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
  }
  
  var isNumeric : Bool {
    return Double(self) != nil
  }
  
  var htmlDecoded: String {
    let decoded = try? NSAttributedString(data: Data(utf8), options: [
      .documentType: NSAttributedString.DocumentType.html,
      .characterEncoding: String.Encoding.utf8.rawValue
    ], documentAttributes: nil).string
    
    return decoded ?? self
  }
}
