//
//  XPCMachServer.swift
//  SecureXPC
//
//  Created by Alexander Momchilov on 2021-11-08
//

import Foundation

/// A concrete implementation of ``XPCServer`` which acts as a server for an XPC Mach service.
///
/// In the case of this framework, the XPC Mach service is expected to be communicated with by an `XPCMachClient`.
internal class XPCMachServer: XPCServer {

	// MARK: Nested

	/// Defines the lifecycle states of the XPCMachServer.
	private enum State {
		/// The server has been initialized but not yet started.
		/// Connections received in this state are held pending the call to `start()`.
		case pending(connections: [xpc_connection_t])
		/// The server is started and actively processing incoming connections.
		case started
		/// The server is shutting down and is waiting for the system to confirm the listener connection has been invalidated.
		case invalidating(queue: DispatchQueue, completion: () -> Void)
		/// The server has been fully invalidated.
		case invalidated

		///
		var isInvalidating: Bool {
			if case .invalidating = self {
				return true
			}
			return false
		}
	}

	// MARK: Properties

    /// Name of the service.
    private let machServiceName: String
    /// Receives new incoming connections
    private let listenerConnection: xpc_connection_t
    /// The dispatch queue used when new connections are being received
    private let listenerQueue: DispatchQueue
	/// The current lifecycle state of the server.
	private var state: State = .pending(connections: [])
    
    /// This should only ever be called from `getXPCMachServer(...)` so that client requirement invariants are upheld.
    private init(criteria: MachServiceCriteria) {
        self.machServiceName = criteria.machServiceName
        let listenerQueue = DispatchQueue(label: String(describing: XPCMachServer.self))
        // Attempts to bind to the Mach service. If this isn't actually a Mach service a EXC_BAD_INSTRUCTION will occur.
        self.listenerConnection = machServiceName.withCString { namePointer in
            xpc_connection_create_mach_service(namePointer, listenerQueue, UInt64(XPC_CONNECTION_MACH_SERVICE_LISTENER))
        }
        self.listenerQueue = listenerQueue
        super.init(clientRequirement: criteria.clientRequirement)
        
        // Configure listener for new connections, all received events are incoming client connections
        xpc_connection_set_event_handler(self.listenerConnection, { event in
			self.listenerQueue.async {
				if xpc_get_type(event) == XPC_TYPE_CONNECTION {
					let clientConnection = event as xpc_connection_t
					switch self.state {
					case .pending(let connections):
						self.state = .pending(connections: connections + [clientConnection])
					case .started:
						self.startClientConnection(clientConnection)
					default:
						// Cancels any new connections that might arrive during invalidation
						xpc_connection_cancel(clientConnection)
					}
				} else if xpc_get_type(event) == XPC_TYPE_ERROR {
					// The only EXPECTED error is `XPC_ERROR_CONNECTION_INVALID` when we are already invalidating.
					if !(self.state.isInvalidating && xpc_equal(event, XPC_ERROR_CONNECTION_INVALID)) {
						let xpcError = XPCError.fromXPCObject(event)
						self.errorHandler.handle(xpcError, nil)
					}

					if case let .invalidating(queue, completion) = self.state {
						self.state = .invalidated
						queue.async { completion() }
					} else {
						// In all error cases, the listener is now dead. Move to the final state.
						self.state = .invalidated
					}
				}
			}
        })
        xpc_connection_resume(self.listenerConnection)
    }

	internal override func invalidate(
		on queue: DispatchQueue,
		completion: @escaping () -> Void
	) {
		self.listenerQueue.sync {
			// Only proceed if the server is in a state that can be invalidated
			switch self.state {
			case .pending, .started:
				// The final transition to `.invalidated` will happen in the event handler
				self.state = .invalidating(queue: queue, completion: completion)
				xpc_connection_cancel(self.listenerConnection)
			case .invalidated:
				// If already invalidated, complete immediately.
				queue.async { completion() }
			case .invalidating:
				// An invalidation is already in progress, ignore this new request.
				break
			}
		}
	}

    public override func startAndBlock() -> Never {
        self.start()

        // Park the main thread, allowing for incoming connections and requests to be processed
        dispatchMain()
    }
    
    public override var connectionDescriptor: XPCConnectionDescriptor {
        .machService(name: machServiceName)
    }
    
    public override var endpoint: XPCServerEndpoint {
        XPCServerEndpoint(connectionDescriptor: .machService(name: self.machServiceName),
                          endpoint: xpc_endpoint_create(self.listenerConnection))
    }
}

extension XPCMachServer: XPCNonBlockingServer {
	/// Transitions the server to the started state and processes any pending connections.
	///
	/// This method performs a one-time transition from the `.pending` to the `.started` state.
	/// Calling it on a server that is already started or has been invalidated will have no effect.
    public func start() {
        self.listenerQueue.sync {
			if case let .pending(connections) = self.state {
				self.state = .started
				for connection in connections {
					self.startClientConnection(connection)
				}
			}
        }
    }
}

extension XPCMachServer: CustomDebugStringConvertible {
    /// Description which includes the name of the service and its memory address (to help in debugging uniqueness bugs)
    var debugDescription: String {
        "\(XPCMachServer.self) [\(self.machServiceName)] \(Unmanaged.passUnretained(self).toOpaque())"
    }
}

/// Contains all of the `static` code that provides the entry points to retrieving an `XPCMachServer` instance.
extension XPCMachServer {
    /// Cache of servers with the machServiceName as the key.
    ///
    /// This exists for correctness reasons, not as a performance optimization. Only one listener connection for a named service can exist simultaneously, so it's
    /// important this invariant be upheld when returning `XPCServer` instances.
    private static var machServerCache = [String : XPCMachServer]()
    
    /// Prevents race conditions for creating and retrieving cached Mach servers
    private static let serialQueue = DispatchQueue(label: "XPCMachServer Retrieval Queue")
    
    /// Returns a server with the provided name and an equivalent client requirement OR throws an error if that's not possible.
    ///
    /// Decision tree:
    /// - If a server exists with that name:
    ///   - If the client requirements are equivalent, return the server.
    ///   - Else, throw an error.
    /// - Else no server exists in the cache with the provided name, create one, store it in the cache, and return it.
    ///
    /// This behavior prevents ending up with two servers for the same named XPC Mach service.
    internal static func getXPCMachServer(criteria: MachServiceCriteria) throws -> XPCMachServer {
        // Force serial execution to prevent a race condition where multiple XPCMachServer instances for the same Mach
        // service name are created and returned
        try serialQueue.sync {
            let server: XPCMachServer
            if let cachedServer = machServerCache[criteria.machServiceName] {
                guard criteria.clientRequirement == cachedServer.clientRequirement else {
                    throw XPCError.conflictingClientRequirements
                }
                server = cachedServer
            } else {
                server = XPCMachServer(criteria: criteria)
                machServerCache[criteria.machServiceName] = server
            }
            
            return server
        }
    }

	/// Asynchronously invalidates a cached server by its Mach service name and removes it from the cache.
	///
	/// This provides a thread-safe way to shut down a specific, shared server instance.
	/// The completion handler is called after the server has been removed from the cache and its
	/// asynchronous invalidation process has been initiated.
	///
	/// If no server with the given name is found, the completion handler is called immediately.
	///
	/// - Parameters:
	///   - machServiceName: The name of the Mach service server to invalidate.
	///   - queue: The dispatch queue on which to execute the completion handler.
	///   - completion: The closure to be called once the operation is complete.
	internal static func invalidateServer(
		named machServiceName: String,
		on queue: DispatchQueue,
		completion: @escaping () -> Void
	) {
		serialQueue.async {
			if let cachedServer = machServerCache[machServiceName] {
				cachedServer.invalidate(on: serialQueue) {
					machServerCache[machServiceName] = nil
					queue.async { completion() }
				}
			} else {
				queue.async { completion() }
			}
		}
	}
}
