//
//  Server Error Handler Test.swift
//  
//
//  Created by Josh Kaplan on 2022-02-23.
//

import Foundation
import XCTest
import SecureXPC

// Note: it's intentional this is *not* `Codable` to validate that server side all errors are sent to the error handler
private enum ExampleError: Error, Equatable {
    case completeAndUtterFailure
}

class ServerErrorHandlerTest: XCTestCase {
    
    func testErrorHandler_Sync()  throws {
        let errorToThrow = ExampleError.completeAndUtterFailure
        let errorExpectation = self.expectation(description: "\(errorToThrow) should be provided to error handler")
        
        let failureRoute = XPCRoute.named("always", "throws")
        let server = XPCServer.makeAnonymous()
        let client = XPCClient.forEndpoint(server.endpoint)
        server.registerRoute(failureRoute) { connectionToken in
            throw ExampleError.completeAndUtterFailure
        }
        server.setErrorHandler { error, connectionToken in
            switch error {
                case .handlerError(let error):
                    if case let .available(underlyingError) = error.underlyingError,
                       underlyingError as? ExampleError == errorToThrow {
                        errorExpectation.fulfill()
                    } else {
                        XCTFail("Unexpected underlying error: \(error)")
                    }
                default:
                    XCTFail("Unexpected error: \(error)")
            }
        }
        
        server.start()
        
        client.send(to: failureRoute, onCompletion: nil)
        
        self.waitForExpectations(timeout: 1)
    }
    
    func testErrorHandler_Async() throws {
        let errorToThrow = ExampleError.completeAndUtterFailure
        let errorExpectation = self.expectation(description: "\(errorToThrow) should be provided to error handler")
        
        let failureRoute = XPCRoute.named("always", "throws")
        let server = XPCServer.makeAnonymous()
        let client = XPCClient.forEndpoint(server.endpoint)
        server.registerRoute(failureRoute) { connectionToken in
            throw ExampleError.completeAndUtterFailure
        }
        server.setErrorHandler { error, connectionToken async -> Void in
            switch error {
                case .handlerError(let error):
                    if case let .available(underlyingError) = error.underlyingError,
                       underlyingError as? ExampleError == errorToThrow {
                        errorExpectation.fulfill()
                    } else {
                        XCTFail("Unexpected underlying error: \(error)")
                    }
                default:
                    XCTFail("Unexpected error: \(error)")
            }
        }
        
        server.start()
        
        client.send(to: failureRoute, onCompletion: nil)
        
        self.waitForExpectations(timeout: 1)
    }
    
    func testErrorHandler_SequentialReply_Sync() throws {
        let errorToThrow = ExampleError.completeAndUtterFailure
        let errorExpectation = self.expectation(description: "\(errorToThrow) should be provided to error handler")
        
        let failureRoute = XPCRoute.named("eventually", "throws")
                                   .withSequentialReplyType(String.self)
        let server = XPCServer.makeAnonymous()
        let client = XPCClient.forEndpoint(server.endpoint)
        
        server.registerRoute(failureRoute) { (connectionToken, provider) in
            provider.failure(error: errorToThrow)
        }
        server.setErrorHandler { error, connectionToken in
            switch error {
                case .handlerError(let error):
                    if case let .available(underlyingError) = error.underlyingError,
                       underlyingError as? ExampleError == errorToThrow {
                        errorExpectation.fulfill()
                    } else {
                        XCTFail("Unexpected underlying error: \(error)")
                    }
                default:
                    XCTFail("Unexpected error: \(error)")
            }
        }
        
        server.start()
        
        client.send(to: failureRoute, withSequentialResponse: { _ in })
        
        self.waitForExpectations(timeout: 1)
    }
    
    func testErrorHandler_SequentialReply_Async() throws {
        let errorToThrow = ExampleError.completeAndUtterFailure
        let errorExpectation = self.expectation(description: "\(errorToThrow) should be provided to error handler")
        
        let failureRoute = XPCRoute.named("eventually", "throws")
                                   .withSequentialReplyType(String.self)
        let server = XPCServer.makeAnonymous()
        let client = XPCClient.forEndpoint(server.endpoint)
        server.registerRoute(failureRoute) { (connectionToken, provider) in
            provider.failure(error: errorToThrow)
        }
        server.setErrorHandler { error, connectionToken async -> Void in
            switch error {
                case .handlerError(let error):
                    if case let .available(underlyingError) = error.underlyingError,
                       underlyingError as? ExampleError == errorToThrow {
                        errorExpectation.fulfill()
                    } else {
                        XCTFail("Unexpected underlying error: \(error)")
                    }
                default:
                    XCTFail("Unexpected error: \(error)")
            }
        }
        
        server.start()
        
        client.send(to: failureRoute, withSequentialResponse: { _ in })
        
        self.waitForExpectations(timeout: 1)
    }
}
