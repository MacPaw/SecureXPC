//
//  ConnectionSession.swift
//  SecureXPC
//
//  Created by Robert Fogash on 07.08.2025.
//

import Foundation

public struct ConnectionId {

    public let id: UUID
    public let clientPid: pid_t

    public init(clientPid: pid_t) {
        self.id = UUID()
        self.clientPid = clientPid
    }

    static func makeEmpty() -> Self {
        ConnectionId(clientPid: -1)
    }
}
