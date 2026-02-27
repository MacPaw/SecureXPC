//
//  Array+XPCRawCodable.swift
//  SecureXPC
//
//  Created by Robert Fogash on 27.02.2026.
//

import Foundation

extension Array: XPCRawEncodable where Array.Element: Trivial {

    func xpcRawValue(codingPath: [any CodingKey]) throws -> xpc_object_t {
        guard let xpcData = encodeArrayAsData(value: self) else {
            let debugDescription = "Unable to encode \(self.self) to XPC data representation"
            let context = EncodingError.Context(codingPath: codingPath,
                                                debugDescription: debugDescription,
                                                underlyingError: nil)
            throw EncodingError.invalidValue(self, context)
        }
        return xpcData
    }

    func encodeArrayAsData(value: Any) -> xpc_object_t? {
        self.withUnsafePointer {
            xpc_data_create($0, self.elementCount * type(of: self).elementStride)
        }
    }
}

extension Array: XPCRawDecodable where Array.Element: Trivial {

    init(xpcRawValue: xpc_object_t, codingPath: [any CodingKey]) throws {
        guard   xpc_get_type(xpcRawValue) == XPC_TYPE_DATA,
                let dataPointer = xpc_data_get_bytes_ptr(xpcRawValue)
        else {
            let context = DecodingError.Context(codingPath: codingPath,
                                                debugDescription: "Unable to decode array",
                                                underlyingError: nil)
            throw DecodingError.dataCorrupted(context)
        }
        self = Array(pointer: dataPointer, count: xpc_data_get_length(xpcRawValue) / MemoryLayout<Element>.size)
    }
}
