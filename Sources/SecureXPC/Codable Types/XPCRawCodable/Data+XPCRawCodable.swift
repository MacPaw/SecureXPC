//
//  File.swift
//  SecureXPC
//
//  Created by Robert Fogash on 27.02.2026.
//

import Foundation

extension Data: XPCRawEncodable {

    func xpcRawValue(codingPath: [any CodingKey]) throws -> xpc_object_t {
        try withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> xpc_object_t in
            guard let baseAddress = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self)
            else {
                let debugDescription = "Unable to encode \(self.self) to XPC data representation"
                let context = EncodingError.Context(codingPath: codingPath,
                                                    debugDescription: debugDescription,
                                                    underlyingError: nil)
                throw EncodingError.invalidValue(self, context)
            }
            return xpc_data_create(baseAddress, buffer.count)
        }
    }
}

extension Data: XPCRawDecodable {

    init(xpcRawValue: xpc_object_t, codingPath: [any CodingKey]) throws {
        guard xpc_get_type(xpcRawValue) == XPC_TYPE_DATA,
              let dataPointer = xpc_data_get_bytes_ptr(xpcRawValue)
        else {
            let context = DecodingError.Context(codingPath: codingPath,
                                                debugDescription: "Unable to decode data",
                                                underlyingError: nil)
            throw DecodingError.dataCorrupted(context)
        }
        self.init(bytes: dataPointer, count: xpc_data_get_length(xpcRawValue))
    }
}
