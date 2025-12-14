//
//  StateOfMindLog.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation

struct StateOfMindLog: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let rating: Int // 1-10 scale or similar
    var notes: String?

    init(id: UUID = UUID(), timestamp: Date = Date(), rating: Int, notes: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.rating = rating
        self.notes = notes
    }
}




