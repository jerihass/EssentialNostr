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
        guard delegate?.stateHandler != nil else { throw Error.stateHandlerNotSet }
        connection.stateUpdateHandler = delegate?.stateHandler
        connection.start(queue: .main)
    }

    public func disconnect() {
        connection.cancel()
    }

    public func send(message: String, completion: @escaping (Swift.Error) -> Void) {
        guard let data = message.data(using: .utf8) else { return }

        send(data, completion: completion)
    }


    public func receive(completion: @escaping (ReceiveResult) -> Void) {
        connection.receiveMessage { content, contentContext, isComplete, error in
            if let content = content, isComplete {
                completion(.success(content))
            }
            if let error = error {
               completion(.failure(Error.networkError(error)))
            }
        }
    }

    private func send(_ data: Data, completion: @escaping (Swift.Error) -> Void) {
        let metaData = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "text", metadata: [metaData])
        connection.send(content: data, contentContext: context, completion: .contentProcessed({ error in
            if let error = error {
                completion(Error.networkError(error))
            }
        }))
    }
}
