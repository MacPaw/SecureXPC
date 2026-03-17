//
//  SingleValueContainerRoundtripTests.swift
//  SecureXPC
//
//  Created by Robert Fogash on 17.03.2026.
//

import XCTest

final class SingleValueContainerRoundtripTests: XCTestCase {

    func test_roundtrip_array_of_integers() throws {
        try assertRoundTripEqual(TestArrayStruct(numbers: [1,2,3]))
    }

    func test_roundtrip_data() throws {
        try assertRoundTripEqual(TestDataStruct(data: Data("Hello".utf8)))
    }
}
