//
//  FileDescriptorXPCContainer Tests.swift
//  SecureXPC
//
//  Created by Josh Kaplan on 2022-07-10
//

import System
import Foundation
import XCTest
import SecureXPC

final class FileDescriptorXPCContainerTests: XCTestCase {
    // MARK: helper functions
    
    private func currentPath(filePath: String = #filePath) -> String { filePath }
    
    private func pathForFileDescriptor(fileDescriptor: Int32) -> String {
        var buffer = [CChar](repeating: 0, count: Int(PATH_MAX))
        _ = fcntl(fileDescriptor, F_GETPATH, &buffer)
        
        return String(cString: buffer)
    }
    
    // MARK: FileDescriptor
    
    func testFileDescriptor_DirectInit() async throws {
        let server = XPCServer.makeAnonymous()
        let client = XPCClient.forEndpoint(server.endpoint)
        let route = XPCRoute.named("fd", "provider")
                            .withReplyType(FileDescriptorForXPC.self)
        server.registerRoute(route) { connectionId in
            FileDescriptorForXPC(wrappedValue: FileDescriptor(rawValue: open(self.currentPath(), O_RDONLY)))
        }
        server.start()
        
        let container = try await client.send(to: route)
        let descriptor = container.wrappedValue
        defer { try! descriptor.close() }
        
        XCTAssertEqual(pathForFileDescriptor(fileDescriptor: descriptor.rawValue), currentPath())
    }
    
    func testFileDescriptor_PropertyWrapper() async throws {
        struct SecureDocument: Codable {
            var securityLevel: Int
            @FileDescriptorForXPC var document: FileDescriptor
        }
        
        let server = XPCServer.makeAnonymous()
        let client = XPCClient.forEndpoint(server.endpoint)
        let route = XPCRoute.named("secure", "document")
                            .withReplyType(SecureDocument.self)
        server.registerRoute(route) { connectionId in
            SecureDocument(securityLevel: 5, document: FileDescriptor(rawValue: open(self.currentPath(), O_RDONLY)))
        }
        server.start()
        
        let document = try await client.send(to: route).document
        defer { try! document.close() }
        
        XCTAssertEqual(pathForFileDescriptor(fileDescriptor: document.rawValue), currentPath())
    }
    
    // MARK: FileHandle
    
    func testFileHandle_DirectInit() async throws {
        let server = XPCServer.makeAnonymous()
        let client = XPCClient.forEndpoint(server.endpoint)
        let route = XPCRoute.named("fd", "provider")
                            .withReplyType(FileHandleForXPC.self)
        server.registerRoute(route) { connectionId in
            FileHandleForXPC(wrappedValue: FileHandle(forReadingAtPath: self.currentPath())!, closeOnEncode: true)
        }
        server.start()
        
        let container = try await client.send(to: route)
        let handle = container.wrappedValue
        defer { try! handle.close() }
        
        XCTAssertEqual(pathForFileDescriptor(fileDescriptor: handle.fileDescriptor), currentPath())
    }
    
    func testFileHandle_PropertyWrapper() async throws {
        struct SecureDocument: Codable {
            var securityLevel: Int
            @FileHandleForXPC var document: FileHandle
        }
        
        let server = XPCServer.makeAnonymous()
        let client = XPCClient.forEndpoint(server.endpoint)
        let route = XPCRoute.named("secure", "document")
                            .withReplyType(SecureDocument.self)
        server.registerRoute(route) { connectionId in
            SecureDocument(securityLevel: 5, document: FileHandle(forReadingAtPath: self.currentPath())!)
        }
        server.start()
        
        let document = try await client.send(to: route).document
        defer { try! document.close() }
        
        XCTAssertEqual(pathForFileDescriptor(fileDescriptor: document.fileDescriptor), currentPath())
    }
    
    // MARK: Automatic bridging
    
    func testAutomaticBridging_DirectInit() async throws {
        let server = XPCServer.makeAnonymous()
        let client = XPCClient.forEndpoint(server.endpoint)
        let serverRoute = XPCRoute.named("fd", "provider")
                                .withReplyType(FileHandleForXPC.self)
        let clientRoute = XPCRoute.named("fd", "provider")
                                .withReplyType(FileDescriptorForXPC.self)
        server.registerRoute(serverRoute) { connectionId in
            FileHandleForXPC(wrappedValue: FileHandle(forReadingAtPath: self.currentPath())!, closeOnEncode: true)
        }
        server.start()
        
        let container = try await client.send(to: clientRoute)
        let descriptor = container.wrappedValue.rawValue
        defer { close(descriptor) }
        
        XCTAssertEqual(pathForFileDescriptor(fileDescriptor: descriptor), currentPath())
    }
    
    func testAutomaticBridging_PropertyWrapper() async throws {
        struct ServerSecureDocument: Codable {
            var securityLevel: Int
            @FileDescriptorForXPC var document: FileDescriptor
        }
        
        struct ClientSecureDocument: Codable {
            var securityLevel: Int
            @FileHandleForXPC var document: FileHandle
        }
        
        let server = XPCServer.makeAnonymous()
        let client = XPCClient.forEndpoint(server.endpoint)
        let serverRoute = XPCRoute.named("secure", "document")
                                .withReplyType(ServerSecureDocument.self)
        let clientRoute = XPCRoute.named("secure", "document")
                                .withReplyType(ClientSecureDocument.self)
        server.registerRoute(serverRoute) { connectionId in
            ServerSecureDocument(securityLevel: 5, document: FileDescriptor(rawValue: open(self.currentPath(), O_RDONLY)))
        }
        server.start()
        
        let container = try await client.send(to: clientRoute)
        let descriptor = container.document.fileDescriptor
        defer { close(descriptor) }
        
        XCTAssertEqual(pathForFileDescriptor(fileDescriptor: descriptor), currentPath())
    }
}
