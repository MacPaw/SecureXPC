//
//  TestArrayStruct.swift
//  SecureXPC
//
//  Created by Robert Fogash on 17.03.2026.
//

import Foundation
@testable import SecureXPC

// This is a testing structure for single value container coder/decoder

struct TestArrayStruct: Codable, Equatable {
    let numbers: [Int]

    init(numbers: [Int]) {
        self.numbers = numbers
    }

    // MARK: Coder

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(numbers)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.numbers = try container.decode([Int].self)
    }
}
