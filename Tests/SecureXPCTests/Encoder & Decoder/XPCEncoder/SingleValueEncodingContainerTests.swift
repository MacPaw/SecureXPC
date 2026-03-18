//
//  SingleValueEncodingContainerTests.swift
//  SecureXPC
//
//  Created by Robert Fogash on 17.03.2026.
//

import XCTest
@testable import SecureXPC

final class SingleValueEncodingContainerTests: XCTestCase {

    func test_singleValueArrayEncoder() throws {
        let testStruct = TestArrayStruct(numbers: [1, 2, 3])
        let encodedTestStruct = try XPCEncoder.encode(testStruct)

        let expected = testStruct.numbers.withUnsafeBufferPointer { pointer in
            xpc_data_create(pointer.baseAddress, pointer.count * MemoryLayout<Int>.stride)
        }

        let isEqual = xpc_equal(expected, encodedTestStruct)
        XCTAssertTrue(isEqual)
    }

    func test_singleValueDataEncoder() throws {
        let testStruct = TestDataStruct(data: Data([1, 2, 3]))
        let encodedTestStruct = try XPCEncoder.encode(testStruct)

        let expected = testStruct.data.withUnsafeBytes {
            xpc_data_create($0.baseAddress, $0.count)
        }
        
        let isEqual = xpc_equal(expected, encodedTestStruct)
        XCTAssertTrue(isEqual)
    }
}
