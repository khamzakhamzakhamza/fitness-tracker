//
//  Item.swift
//  fitness-tracker
//
//  Created by Taranova, Kseniia on 04/09/2026.
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
