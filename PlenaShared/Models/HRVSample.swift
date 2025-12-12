//
//  HRVSample.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation

struct HRVSample: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let sdnn: Double // Standard Deviation of NN intervals (ms)

    init(id: UUID = UUID(), timestamp: Date = Date(), sdnn: Double) {
        self.id = id
        self.timestamp = timestamp
        self.sdnn = sdnn
    }
}


