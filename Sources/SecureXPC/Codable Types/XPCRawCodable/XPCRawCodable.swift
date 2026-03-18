//
//  File.swift
//  SecureXPC
//
//  Created by Robert Fogash on 27.02.2026.
//

import Foundation

protocol XPCRawEncodable {

    func xpcRawValue() -> xpc_object_t?
}

protocol XPCRawDecodable {

    init?(xpcRawValue: xpc_object_t)
}

typealias XPCRawCodable = XPCRawDecodable & XPCRawEncodable
