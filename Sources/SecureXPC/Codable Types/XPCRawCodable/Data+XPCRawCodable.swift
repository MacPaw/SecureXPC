//
//  File.swift
//  SecureXPC
//
//  Created by Robert Fogash on 27.02.2026.
//

import Foundation

extension Data: XPCRawEncodable {

    func xpcRawValue() -> xpc_object_t? {
        withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> xpc_object_t? in
            guard let baseAddress = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self)
            else {
                return nil
            }
            return xpc_data_create(baseAddress, buffer.count)
        }
    }
}

extension Data: XPCRawDecodable {

    init?(xpcRawValue: xpc_object_t) {
        guard xpc_get_type(xpcRawValue) == XPC_TYPE_DATA,
              let dataPointer = xpc_data_get_bytes_ptr(xpcRawValue)
        else {
            return nil
        }
        self.init(bytes: dataPointer, count: xpc_data_get_length(xpcRawValue))
    }
}
