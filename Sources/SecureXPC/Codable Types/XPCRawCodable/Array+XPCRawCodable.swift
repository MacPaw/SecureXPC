//
//  Array+XPCRawCodable.swift
//  SecureXPC
//
//  Created by Robert Fogash on 27.02.2026.
//

import Foundation

extension Array: XPCRawEncodable where Array.Element: Trivial {

    func xpcRawValue() -> xpc_object_t? {
        self.withUnsafePointer {
            xpc_data_create($0, self.elementCount * type(of: self).elementStride)
        }
    }
}

extension Array: XPCRawDecodable where Array.Element: Trivial {

    init?(xpcRawValue: xpc_object_t) {
        guard   xpc_get_type(xpcRawValue) == XPC_TYPE_DATA,
                let dataPointer = xpc_data_get_bytes_ptr(xpcRawValue)
        else {
            return nil
        }
        self = Array(pointer: dataPointer, count: xpc_data_get_length(xpcRawValue) / MemoryLayout<Element>.size)
    }
}
