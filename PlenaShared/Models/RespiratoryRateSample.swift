//
//  RespiratoryRateSample.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation

struct RespiratoryRateSample: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let value: Double // breaths per minute

    init(id: UUID = UUID(), timestamp: Date = Date(), value: Double) {
        self.id = id
        self.timestamp = timestamp
        self.value = value
    }
}


