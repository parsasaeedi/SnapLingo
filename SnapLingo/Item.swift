//
//  Item.swift
//  SnapLingo
//
//  Created by Parsa Saeedi on 2025-08-23.
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
