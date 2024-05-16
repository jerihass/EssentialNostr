//
//  Created by Jericho Hasselbush on 5/16/24.
//

import XCTest
import Network

class NetworkConnectionWebSocketClient {
    let connection: NWConnection
    var state: NWConnection.State { connection.state }
    var stateHandler: ((_ state: NWConnection.State) -> Void)?

    enum Error: Swift.Error {
        case stateHandlerNotSet
    }

    init() {
        let url = URL(string: "wss://127.0.0.1:8080")!
        let endpoint = NWEndpoint.url(url)
        let parameters = NWParameters(tls: nil)
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
}


class NetworkConnectionWebSocketClientTests: XCTestCase {
    func test_throwsError_withoutStateHandlerSetOnStart() {
        let sut = NetworkConnectionWebSocketClient()
        XCTAssertThrowsError(try sut.start(), "Expected error without state handler set")
    }
}
