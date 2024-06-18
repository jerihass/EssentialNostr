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

    func disconnect() {
        pool.forEach {$0.disconnect() }
    }

    func send(message: String) {
        pool.forEach({ $0.send(message: message, completion: { _ in })})
    }
}

class WebSocketPoolTests: XCTestCase {
    func test_add_doesNotSendMessagesToPool() {
        let sut = WebSocketPool()
        let client = ClientSpy()

        sut.add(client: client)

        XCTAssertTrue(client.receivedMessages.isEmpty)
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

    func test_disconnect_sendsDisconnectToPool() {
        let sut = WebSocketPool()
        let client = ClientSpy()
        let client2 = ClientSpy()
        sut.add(client: client)
        sut.add(client: client2)

        sut.disconnect()

        let spys = sut.pool.compactMap({ $0 as? ClientSpy })
        for (index, client) in spys.enumerated() {
            XCTAssertEqual(client.receivedMessages, [.disconnect], "Client at index \(index) failed.")
        }
    }

    func test_send_sendsMessageToPool() {
        let sut = WebSocketPool()
        let client = ClientSpy()
        let client2 = ClientSpy()
        sut.add(client: client)
        sut.add(client: client2)

        sut.send(message: "A Message")

        let spys = sut.pool.compactMap({ $0 as? ClientSpy })
        for (index, client) in spys.enumerated() {
            XCTAssertEqual(client.receivedMessages, [.send("A Message")], "Client at index \(index) failed.")
        }
    }


    private class ClientSpy: WebSocketClient {
        enum Message: Equatable {
            case start
            case disconnect
            case send(String)
        }
        var receivedMessages = [Message]()
        var stateHandler: ((EssentialNostr.WebSocketDelegateState) -> Void)?
        func start() throws { receivedMessages.append(.start) }
        func disconnect() { receivedMessages.append(.disconnect) }
        func send(message: String, completion: @escaping (Error) -> Void) { receivedMessages.append(.send(message))}
        func receive(completion: @escaping (ReceiveResult) -> Void) {}
    }
}
