//
//  Created by Jericho Hasselbush on 5/16/24.
//

import Foundation
import Network

public class NetworkConnectionWebSocketClient {
    private let connection: NWConnection
    public var stateHandler: ((_ state: NWConnection.State) -> Void)?
    public var receiveHandler: ((_ data: Data) -> Void)?

    private enum Error: Swift.Error {
        case stateHandlerNotSet
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

    public func receive(with request: String) {
        guard receiveHandler != nil else { return }

        let data = request.data(using: .utf8)!
        send(data)

        connection.receiveMessage { content, contentContext, isComplete, error in
            if let content = content, isComplete {
                self.receiveHandler?(content)
            }
        }
    }

    private func send(_ data: Data) {
        let metaData = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "text", metadata: [metaData])
        connection.send(content: data, contentContext: context, completion: .contentProcessed({ _ in}))
    }
}
