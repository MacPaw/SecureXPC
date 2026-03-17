//
//  TestDataStruct.swift
//  SecureXPC
//
//  Created by Robert Fogash on 17.03.2026.
//

import Foundation
@testable import SecureXPC

struct TestDataStruct: Codable, Equatable {
    let data: Data

    init(data: Data) {
        self.data = data
    }

    // MARK: Codable

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.data = try container.decode(Data.self)
    }
}
