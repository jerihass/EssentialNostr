//
//  Created by Jericho Hasselbush on 6/18/24.
//

import XCTest
import EssentialNostr

class WebSocketPool {
    var pool = [WebSocketClient]()
    var errorHandler: (Error) -> Void

    init() {
        self.errorHandler = { _ in }
    }

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
        pool.forEach({ client in
            client.send(message: message,
                        completion: errorHandler)
        })
    }

    func receive() {
        pool.forEach({ client in
            client.receive { _ in }
        })
    }
}

class WebSocketPoolTests: XCTestCase {
    func test_add_doesNotSendMessagesToPool() {
        let (_, clients) = makeSUT()

        XCTAssertTrue(clients[0].receivedMessages.isEmpty)
    }

    func test_add_addsClientToPool() {
        let (sut, clients) = makeSUT()

        XCTAssertEqual(sut.pool.count, clients.count)
    }

    func test_start_sendsStartToPool() throws {
        let (sut, clients) = makeSUT()

        try sut.start()

        for (index, client) in clients.enumerated() {
            XCTAssertEqual(client.receivedMessages, [.start], "Client at index \(index) failed.")
        }
    }

    func test_disconnect_sendsDisconnectToPool() {
        let (sut, clients) = makeSUT()

        sut.disconnect()

        for (index, client) in clients.enumerated() {
            XCTAssertEqual(client.receivedMessages, [.disconnect], "Client at index \(index) failed.")
        }
    }

    func test_send_sendsMessageToPool() {
        let (sut, clients) = makeSUT()

        sut.send(message: "A Message")

        for (index, client) in clients.enumerated() {
            XCTAssertEqual(client.receivedMessages, [.send("A Message")], "Client at index \(index) failed.")
        }
    }

    func test_send_givesErrorOnSendError() {
        let (sut, clients) = makeSUT()

        var errors = [Error]()
        let errorHandler: (Error) -> Void = { error in
            errors.append(error)
        }

        sut.errorHandler = errorHandler

        sut.send(message: "A Message")

        let sendError = anyError()

        for client in clients {
            client.completeSendWith(sendError)
        }

        XCTAssertEqual(errors.map({ $0 as NSError? }), [sendError, sendError])
    }

    func test_receive_receiveMessageToPool() {
        let (sut, clients) = makeSUT()

        sut.receive()

        for (index, client) in clients.enumerated() {
            XCTAssertEqual(client.receivedMessages, [.receive], "Client at index \(index) failed.")
        }
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: WebSocketPool, clients: [ClientSpy]) {
        let sut = WebSocketPool()
        let client = ClientSpy()
        let client2 = ClientSpy()

        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(client)
        trackForMemoryLeaks(client2)

        sut.add(client: client)
        sut.add(client: client2)

        return (sut, [client, client2])
    }

    private class ClientSpy: WebSocketClient {
        enum Message: Equatable {
            case start
            case disconnect
            case send(String)
            case receive
        }
        var receivedMessages = [Message]()
        var sendCompletions = [(Error) -> Void]()
        var stateHandler: ((EssentialNostr.WebSocketDelegateState) -> Void)?
        func start() throws { receivedMessages.append(.start) }
        func disconnect() { receivedMessages.append(.disconnect) }
        func send(message: String, completion: @escaping (Error) -> Void) {
            receivedMessages.append(.send(message))
            sendCompletions.append(completion)
        }
        func receive(completion: @escaping (ReceiveResult) -> Void) {
            receivedMessages.append(.receive)
        }

        func completeSendWith(_ error: Error, at index: Int = 0) {
            sendCompletions[index](error)
        }
    }
}
