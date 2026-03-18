//
//  OptimizedDataEncoding.swift
//  SecureXPC
//
//  Created by Robert Fogash on 27.02.2026.
//

import XCTest
@testable import SecureXPC

final class OptimizedDataEncoding: XCTestCase {

    static var data: Data!
    var data: Data { Self.data }
    static let dataDize = 2 * 1024 * 1024 // (2 MB)

    override class func setUp() {
        super.setUp()

        data = makeRandomData(sizeInBytes: dataDize)
    }

    override class func tearDown() {
        data = nil
    }

    // If there is no Data encoding optimization - these tests
    // would run for a long time (at least few seconds)

    func test_arrayOfData() throws {

        struct StructureWithArrayOfData: Codable, Equatable {
            let specialData: [Data]
            let text: String
            let number: Int
        }

        let testStructure = StructureWithArrayOfData(specialData: [data], text: "STUB_TEXT", number: 35)
        try assertRoundTripEqual(testStructure)
    }

    func test_arrayOfArrayOfData() throws {

        struct StructureWithArrayOfArrayOfData: Codable, Equatable {
            let specialData: [[Data]]
            let text: String
            let number: Int
        }

        let testStructure = StructureWithArrayOfArrayOfData(specialData: [[data]], text: "STUB_TEXT", number: 35)
        try assertRoundTripEqual(testStructure)
    }

    func test_dataAsProperty() throws {

        struct StructureDataAsProperty: Codable, Equatable {
            let specialData: Data
            let text: String
            let number: Int
        }

        let testStructure = StructureDataAsProperty(specialData: data, text: "STUB_TEXT", number: 35)

        try assertRoundTripEqual(testStructure)
    }

    func test_dataAsRoot() throws {
        try assertRoundTripEqual(data)
    }
}

private extension OptimizedDataEncoding {

    static func makeRandomData(sizeInBytes: Int) -> Data {
        let randomBytes = (0..<sizeInBytes).map { _ in UInt8.random(in: 0...UInt8.max) }
        return Data(randomBytes)
    }
}
