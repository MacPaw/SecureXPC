//
//  SingleValueDecodignContainerTests.swift
//  SecureXPC
//
//  Created by Robert Fogash on 17.03.2026.
//

import XCTest
@testable import SecureXPC

final class SingleValueDecodingContainerTests: XCTestCase {

    func test_decodeArray() throws {
        let expected = TestArrayStruct(numbers: [1, 2, 3])

        let encoded = expected.numbers.withUnsafeBufferPointer { pointer in
            xpc_data_create(pointer.baseAddress, pointer.count * MemoryLayout<Int>.stride)
        }

        let decoded = try XPCDecoder.decode(TestArrayStruct.self, object: encoded)

        XCTAssertEqual(expected, decoded)
    }

    func test_decodeData() throws {
        let data = Data("Hello".utf8)

        let expected = TestDataStruct(data: data)
        let rawEncoded = data.withUnsafeBytes { buffer in
            xpc_data_create(buffer.baseAddress, buffer.count)
        }

        let decoded = try XPCDecoder.decode(TestDataStruct.self, object: rawEncoded)

        XCTAssertEqual(expected, decoded)
    }
}
