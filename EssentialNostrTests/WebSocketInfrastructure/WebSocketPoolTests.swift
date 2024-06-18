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

    func start() throws {
        try pool.forEach { try $0.start() }
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

    func test_start_sendsStartToPool() throws {
        let sut = WebSocketPool()
        let client = ClientSpy()
        let client2 = ClientSpy()
        sut.add(client: client)
        sut.add(client: client2)
        try sut.start()

        let spys = sut.pool.compactMap({ $0 as? ClientSpy })
        for (index, client) in spys.enumerated() {
            XCTAssertEqual(client.receivedMessages, [.start], "Client at index \(index) failed.")
        }
    }


    private class ClientSpy: WebSocketClient {
        enum Message {
            case start
        }
        var receivedMessages = [Message]()
        var stateHandler: ((EssentialNostr.WebSocketDelegateState) -> Void)?
        func start() throws { receivedMessages.append(.start) }
        func disconnect() {}
        func send(message: String, completion: @escaping (Error) -> Void) {}
        func receive(completion: @escaping (ReceiveResult) -> Void) {}
    }

    private class PoolSpy {
        var receivedMessages = [Any]()
    }
}
