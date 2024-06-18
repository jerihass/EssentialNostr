//
//  Created by Jericho Hasselbush on 6/18/24.
//

import XCTest
import EssentialNostr

class WebSocketPool {
    var pool = [WebSocketClient]()
    func add(client: WebSocketClient) {
        pool.append(client)
    }
}

class WebSocketPoolTests: XCTestCase {
    func test_init_poolDoesNotSendMessagesToPool() {
        let _ = WebSocketPool()
        let pool = PoolSpy()

        XCTAssertTrue(pool.receivedMessages.isEmpty)
    }

    func test_add_addsClientToPool() {
        let sut = WebSocketPool()
        let client = ClientSpy()
        sut.add(client: client)

        XCTAssertEqual(sut.pool.count, 1)
    }


    private class ClientSpy: WebSocketClient {
        var stateHandler: ((EssentialNostr.WebSocketDelegateState) -> Void)?
        func start() throws {}
        func disconnect() {}
        func send(message: String, completion: @escaping (Error) -> Void) {}
        func receive(completion: @escaping (ReceiveResult) -> Void) {}
    }

    private class PoolSpy {
        var receivedMessages = [Any]()
    }
}
