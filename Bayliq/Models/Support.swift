//
//  Support.swift
//  Bayliq
//
//  Created by Bhavesh Patel on 08/06/23.
//

import Foundation
import UIKit

struct Support: Identifiable, Codable, Equatable {
    let id = UUID()
    var imageUrl: String = ""
    var name: String = ""
    var address: String = ""
}
