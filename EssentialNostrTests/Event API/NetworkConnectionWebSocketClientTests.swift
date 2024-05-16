//
//  Created by Jericho Hasselbush on 5/16/24.
//

import XCTest
import Network

class NetworkConnectionWebSocketClient {
    let connection: NWConnection
    var state: NWConnection.State { connection.state }
    var stateHandler: ((_ state: NWConnection.State) -> Void)?
    var receiveHandler: ((_ data: Data) -> Void)?

    enum Error: Swift.Error {
        case stateHandlerNotSet
    }

    init() {
        let url = URL(string: "wss://127.0.0.1:8080")!
        let endpoint = NWEndpoint.url(url)
        let parameters = NWParameters(tls: nil, tcp: .init())
        let options = NWProtocolWebSocket.Options()
        parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)
        let connection = NWConnection(to: endpoint, using: parameters)
        self.connection = connection
    }

    func start() throws {
        guard stateHandler != nil else { throw Error.stateHandlerNotSet }
        connection.stateUpdateHandler = stateHandler
        connection.start(queue: .main)
    }

    func receive(with request: String) {
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


class NetworkConnectionWebSocketClientTests: XCTestCase {
    func test_throwsError_withoutStateHandlerSetOnStart() {
        let sut = NetworkConnectionWebSocketClient()
        XCTAssertThrowsError(try sut.start(), "Expected error without state handler set")
    }

    func test_start_continuesToReadyStateOnGoodConnection() {
        let sut = NetworkConnectionWebSocketClient()
        var state: NWConnection.State?

        let exp = expectation(description: "Wait for ready")
        sut.stateHandler = { s in
            if case .ready = s {
                state = s
                exp.fulfill()
            }
        }

        try? sut.start()

        wait(for: [exp], timeout: 0.2)

        XCTAssertEqual(state, .ready)
    }

    func test_receive_sendsRequestToServer() {
        let sut = NetworkConnectionWebSocketClient()
        var echo: Data?
        let request = "Request"
        let data = request.data(using: .utf8)!

        let exp = expectation(description: "Wait for ready")

        sut.stateHandler = {
            if $0 == .ready { sut.receive(with: request) }
        }

        sut.receiveHandler = {
            echo = $0
            exp.fulfill()
        }

        try? sut.start()

        wait(for: [exp], timeout: 0.2)

        XCTAssertEqual(echo, data)
    }
}
