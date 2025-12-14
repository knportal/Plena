//
//  TemperatureSample.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation

struct TemperatureSample: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let value: Double // Body temperature in Celsius

    init(id: UUID = UUID(), timestamp: Date = Date(), value: Double) {
        self.id = id
        self.timestamp = timestamp
        self.value = value
    }
}



