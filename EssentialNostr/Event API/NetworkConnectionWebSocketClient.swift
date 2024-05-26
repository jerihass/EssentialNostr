//
//  Created by Jericho Hasselbush on 5/16/24.
//

import Foundation
import Network

class NWConnectionWebSocketDelegate {
    static func map(_ handler: @escaping (WebSocketDelegateState) -> Void) -> ((NWConnection.State) -> Void) {
        { state in
            switch state {
            case .ready:
                handler(.ready)
            case .setup:
                break
            case .waiting(_):
                break
            case .preparing:
                break
            case .failed(_):
                break
            case .cancelled:
                handler(.cancelled)
            @unknown default:
                break
            }
        }
    }
}

public class NetworkConnectionWebSocketClient: WebSocketClient {
    public var stateHandler: ((_ state: WebSocketDelegateState) -> Void)?
    private let connection: NWConnection

    public enum Error: Swift.Error, Equatable {
        case stateHandlerNotSet
        case networkError(NWError)
    }

    public init(url: URL) {
        let endpoint = NWEndpoint.url(url)
        //let tlsOptions = NWProtocolTLS.Options()
        let tcpOptions = NWProtocolTCP.Options()
        let parameters = NWParameters(tls: nil/*tlsOptions*/, tcp: tcpOptions)
        let options = NWProtocolWebSocket.Options()
        parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)
        let connection = NWConnection(to: endpoint, using: parameters)
        self.connection = connection
    }

    public func start() throws {
        guard let stateHandler = stateHandler else { throw Error.stateHandlerNotSet }
        connection.stateUpdateHandler = NWConnectionWebSocketDelegate.map(stateHandler)
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
