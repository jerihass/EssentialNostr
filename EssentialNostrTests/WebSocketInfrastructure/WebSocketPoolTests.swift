//
//  Created by Jericho Hasselbush on 6/18/24.
//

import XCTest
import EssentialNostr

class WebSocketPool {
    typealias PoolReceiveHandler = (WebSocketClient.ReceiveResult) -> Void
    var pool = [WebSocketClient]()
    var sendErrorHandler: (Error) -> Void
    var receiveHandler: PoolReceiveHandler
    init() {
        self.sendErrorHandler = { _ in }
        self.receiveHandler = { _ in }
    }

    func add(client: WebSocketClient) {
        pool.append(client)
    }

    func start() throws {
        try pool.forEach { try $0.start() }
    }

    func disconnect() {
        pool.forEach { $0.disconnect() }
    }

    func send(message: String) {
        pool.forEach({ $0.send(message: message, completion: sendErrorHandler) })
    }

    func receive() {
        pool.forEach({ $0.receive(completion: receiveHandler) })
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

        sut.sendErrorHandler = errorHandler

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

    func test_receive_givesErrorOnReceiveError() {
        let (sut, clients) = makeSUT()
        let receiveError = anyError()

        expect(sut, toCompleteReceiveWith: .failure(receiveError), resultCount: clients.count) {
            for client in clients {
                client.completeReceiveWith(receiveError)
            }
        }
    }

    func test_receive_givesDataOnSuccess() {
        let (sut, clients) = makeSUT()
        let data = Data()

        expect(sut, toCompleteReceiveWith: .success(data), resultCount: clients.count) {
            for client in clients {
                client.completeReceiveWith(data)
            }
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

    private func expect(_ sut: WebSocketPool, toCompleteReceiveWith expected: WebSocketClient.ReceiveResult, resultCount: Int, file: StaticString = #file, line: UInt = #line, when action: () -> Void) {
        var results = [WebSocketClient.ReceiveResult]()
        let receiveHandler: WebSocketPool.PoolReceiveHandler = { result in
            results.append(result)
        }
        sut.receiveHandler = receiveHandler
        sut.receive()

        action()

        XCTAssertEqual(results.count, resultCount)

        for result in results {
            switch (result, expected) {
            case let (.failure(gotError), .failure(expectedError)):
                XCTAssertEqual(gotError as NSError?, expectedError as NSError?)
            case let (.success(gotData), .success(expectedData)):
                XCTAssertEqual(gotData, expectedData)
            default:
                XCTFail("Expected \(expected), got \(result) instead")
            }
        }
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
        var receiveCompletions = [WebSocketPool.PoolReceiveHandler]()
        var stateHandler: ((EssentialNostr.WebSocketDelegateState) -> Void)?
        func start() throws { receivedMessages.append(.start) }
        func disconnect() { receivedMessages.append(.disconnect) }
        func send(message: String, completion: @escaping (Error) -> Void) {
            receivedMessages.append(.send(message))
            sendCompletions.append(completion)
        }
        func receive(completion: @escaping (ReceiveResult) -> Void) {
            receivedMessages.append(.receive)
            receiveCompletions.append(completion)
        }

        func completeSendWith(_ error: Error, at index: Int = 0) {
            sendCompletions[index](error)
        }

        func completeReceiveWith(_ error: Error, at index: Int = 0) {
            receiveCompletions[index](.failure(error))
        }

        func completeReceiveWith(_ data: Data, at index: Int = 0) {
            receiveCompletions[index](.success(data))
        }
    }
}
