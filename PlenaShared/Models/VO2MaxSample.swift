//
//  VO2MaxSample.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation

struct VO2MaxSample: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let value: Double // VO2 Max in mL/kg/min

    init(id: UUID = UUID(), timestamp: Date = Date(), value: Double) {
        self.id = id
        self.timestamp = timestamp
        self.value = value
    }
}

