//
//  Created by Jericho Hasselbush on 5/23/24.
//

import XCTest
import EssentialNostr

struct URLSessionWSDelegate: WebSocketDelegate {
    var state: WebSocketDelegateState = .cancelled
    var stateHandler: ((EssentialNostr.WebSocketDelegateState) -> Void)?
}

class URLSessionWebSocketClient {
    let url: URL
    let session: URLSession
    var delegate: URLSessionWSDelegate?
    var task: URLSessionWebSocketTask?

    public enum Error: Swift.Error, Equatable {
        case stateHandlerNotSet
        case sendError
        case receiveError
    }

    init(session: URLSession, url: URL) {
        self.session = session
        self.url = url
    }

    func start() throws {
        guard let stateHandler = delegate?.stateHandler else { throw Error.stateHandlerNotSet }
        delegate?.state = .ready
        stateHandler(.ready)
        self.task = session.webSocketTask(with: url)
        task?.resume()
    }

    func disconnect() {
        delegate?.state = .cancelled
        delegate?.stateHandler?(.cancelled)
    }

    func send(message: String, completion: @escaping (Swift.Error) -> Void) {
        guard delegate?.state == .ready else {
            completion(Error.sendError)
            return
        }
        task?.send(.string(message)) {
            if let error = $0 {
                completion(error)
            }
        }
    }

    func receive(completion: @escaping (_ result: Result<Data, Swift.Error>) -> Void) {
        guard delegate?.state == .ready else {
            completion(.failure(Error.receiveError))
            return
        }
        task?.receive { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(message):
                switch message {
                case let .data(data):
                    completion(.success(data))
                case let .string(string):
                    completion(.success(string.data(using: .utf8)!))
                @unknown default:
                    break
                }
            }
        }
    }
}

class URLSessionWebSocketClientTests: XCTestCase {
    func test_throwsError_withoutStateHandlerSetOnStart() {
        let (sut, _) = makeSUT()
        XCTAssertThrowsError(try sut.start(), "Expected error without state handler set")
    }

    func test_start_setsStateToReady() {
        let (sut, _) = makeSUT()

        expect(sut, toChangeToState: .ready) {
            try? sut.start()
        }
    }

    func test_disconnect_cancelsConnection() {
        let (sut, _) = makeSUT()
        try? sut.start()

        expect(sut, toChangeToState: .cancelled) {
            sut.disconnect()
        }
    }

    func test_send_withErrorGivesError() {
        let (sut, _) = makeSUT()

        expect(sut, toCompleteSendWithError: .sendError) {
            sut.disconnect()
        }
    }

    func test_send_noErrorGivesNoError() {
        let (sut, _) = makeSUT()
        expect(sut, toCompleteSendWithError: .none) { }
    }

    func test_receive_withErrorGivesError() {
        let (sut, _) = makeSUT()
        let request = makeRequest()

        sut.delegate?.stateHandler = sendRequestOnReady(sut, request)

        expect(sut, toReceiveWith: .failure(URLSessionWebSocketClient.Error.receiveError)) {
            sut.disconnect()
        }
    }

    func test_receive_noErrorGivesData() throws {
        let (sut, _) = makeSUT()
        let request = makeRequest()
        let requestData = request.data(using: .utf8)!
        sut.delegate?.stateHandler = { _ in }
        try sut.start()

        expect(sut, toReceiveWith: .success(requestData)) {
            sut.send(message: request, completion: { _ in })
        }
    }

    // MARK: - Helpers

    func makeSUT() -> (sut: URLSessionWebSocketClient, task: URLSession) {
        let url = URL(string: "ws://127.0.0.1:8080")!
        let session = URLSession(configuration: .ephemeral)
        let sut = URLSessionWebSocketClient(session: session, url: url)
        let delegate = URLSessionWSDelegate()
        sut.delegate = delegate
        return (sut, session)
    }

    private func sendRequestOnReady(_ sut: URLSessionWebSocketClient, _ request: String) -> (WebSocketDelegateState) -> Void {
        return { [weak sut] in
            if $0 == .ready {
                sut?.send(message: request, completion: { _ in })
            }
        }
    }

    private func expect(_ sut: URLSessionWebSocketClient, toChangeToState expected: WebSocketDelegateState, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        var state: WebSocketDelegateState?

        let exp = expectation(description: "Wait for ready")

        sut.delegate?.stateHandler = {
            if .ready == $0 {
                state = .ready
                exp.fulfill()
            }

            if .cancelled == $0 {
                state = .cancelled
                exp.fulfill()
            }
        }

        action()

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(state, expected, file: file, line: line)
    }

    func expect(_ sut: URLSessionWebSocketClient, toCompleteSendWithError expectedError: URLSessionWebSocketClient.Error?, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let request = makeRequest()
        let exp = expectation(description: "Wait for send completion")
        var error: URLSessionWebSocketClient.Error?
        sut.delegate?.stateHandler = { _ in }

        try? sut.start()

        action()

        sut.send(message: request) {
            error = $0 as? URLSessionWebSocketClient.Error
            exp.fulfill()
        }
        if expectedError == .none {
            XCTExpectFailure {
                wait(for: [exp], timeout: 1)
            }
        } else {
            wait(for: [exp], timeout: 1)
        }

        XCTAssertEqual(error, expectedError, file: file, line: line)
    }

    private func expect(_ sut: URLSessionWebSocketClient, toReceiveWith expected:  Result<Data, Error>, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for receive error")

        try? sut.start()

        action()

        sut.receive { result in
            switch (result, expected) {
            case let (.failure(capturedError), .failure(expectedError)):
                let capturedError = capturedError as? URLSessionWebSocketClient.Error
                let expectedError = expectedError as? URLSessionWebSocketClient.Error
                XCTAssertEqual(capturedError, expectedError, file: file, line: line)
            case let(.success(capturedData), .success(expectedData)):
                XCTAssertEqual(capturedData, expectedData)
            default:
                XCTFail("Expected \(expected), got \(result) instead.", file: file, line: line)
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }

    private func makeRequest() -> String {
        let filter = Filter(kinds: [1], since: .now)
        let sub = "mySub"

        let request = ClientMessage.Message.request(sub: sub, filters: [filter])
        return ClientMessageMapper.mapMessage(request)
    }
}
