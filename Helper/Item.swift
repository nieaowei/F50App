//
//  Item.swift
//  Helper
//
//  Created by Nekilc on 2025/9/28.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
