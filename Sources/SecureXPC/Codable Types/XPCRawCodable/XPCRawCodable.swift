//
//  File.swift
//  SecureXPC
//
//  Created by Robert Fogash on 27.02.2026.
//

import Foundation

protocol XPCRawEncodable {

    func xpcRawValue(codingPath: [any CodingKey]) throws -> xpc_object_t
}

protocol XPCRawDecodable {

    init(xpcRawValue: xpc_object_t, codingPath: [any CodingKey]) throws
}

typealias XPCRawCodable = XPCRawDecodable & XPCRawEncodable
