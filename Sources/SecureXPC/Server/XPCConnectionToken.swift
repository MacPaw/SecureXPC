//
//  ConnectionSession.swift
//  SecureXPC
//
//  Created by Robert Fogash on 07.08.2025.
//

import Foundation

public struct XPCConnectionToken {

    public let id: UUID
    public let clientPID: pid_t

    public init(clientPID: pid_t) {
        self.id = UUID()
        self.clientPID = clientPID
    }
}
