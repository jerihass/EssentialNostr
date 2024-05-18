//
//  Created by Jericho Hasselbush on 5/16/24.
//

import Foundation
import Network

public class NetworkConnectionWebSocketClient: WebSocketClient {
    public var delegate: WebSocketDelegate?
    
    private let connection: NWConnection
    public var stateHandler: ((_ state: NWConnection.State) -> Void)?
    public var receiveHandler: ((_ result: ReceiveResult) -> Void)?

    public enum Error: Swift.Error, Equatable {
        case stateHandlerNotSet
        case networkError(NWError)
    }

    public init(url: URL) {
        let endpoint = NWEndpoint.url(url)
        let parameters = NWParameters(tls: nil, tcp: .init())
        let options = NWProtocolWebSocket.Options()
        parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)
        let connection = NWConnection(to: endpoint, using: parameters)
        self.connection = connection
    }

    public func start() throws {
        guard stateHandler != nil else { throw Error.stateHandlerNotSet }
        connection.stateUpdateHandler = stateHandler
        connection.start(queue: .main)
    }

    public func disconnect() {
        connection.cancel()
    }

    public func receive(with request: String, completion: @escaping (ReceiveResult) -> Void) {
        guard receiveHandler != nil else { return }
        guard let data = request.data(using: .utf8) else { return }

        send(data, completion: completion)
        receive()
    }

    private func receive() {
        connection.receiveMessage { content, contentContext, isComplete, error in
            if let content = content, isComplete {
                self.receiveHandler?(.success(content))
            }
            if let error = error {
                self.receiveHandler?(.failure(Error.networkError(error)))
            }
        }
    }

    private func send(_ data: Data, completion: @escaping (ReceiveResult) -> Void) {
        let metaData = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "text", metadata: [metaData])
        connection.send(content: data, contentContext: context, completion: .contentProcessed({ error in
            if let error = error {
                completion(.failure(Error.networkError(error)))
            }
        }))
    }
}
