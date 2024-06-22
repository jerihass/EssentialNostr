//
//  Created by Jericho Hasselbush on 6/22/24.
//

import Foundation

public class WebSocketPool {
    public typealias PoolReceiveHandler = (WebSocketClient.ReceiveResult) -> Void
    private(set) public var pool = [WebSocketClient]()
    public var sendErrorHandler: (Error) -> Void
    public var receiveHandler: PoolReceiveHandler
    public init() {
        self.sendErrorHandler = { _ in }
        self.receiveHandler = { _ in }
    }

    public func add(client: WebSocketClient) {
        pool.append(client)
    }

    public func start() throws {
        try pool.forEach { try $0.start() }
    }

    public func disconnect() {
        pool.forEach { $0.disconnect() }
    }

    public func send(message: String) {
        pool.forEach({ $0.send(message: message, completion: sendErrorHandler) })
    }

    public func receive() {
        pool.forEach({ $0.receive(completion: receiveHandler) })
    }
}
