//
//  Created by Jericho Hasselbush on 5/16/24.
//

import XCTest
import Network
import EssentialNostr

class NetworkConnectionWebSocketClientTests: XCTestCase {
    func test_throwsError_withoutStateHandlerSetOnStart() {
        let sut = makeSUT()
        XCTAssertThrowsError(try sut.start(), "Expected error without state handler set")
    }

    func test_start_setsStateToReady() {
        let sut = makeSUT()

        expect(sut, toChangeToState: .ready) {
            try? sut.start()
        }
    }

    func test_disconnect_cancelsConnection() {
        let sut = makeSUT()

        expect(sut, toChangeToState: .cancelled) {
            try? sut.start()
            sut.disconnect()
        }
    }

    func test_send_withErrorGivesError() {
        let sut = makeSUT()

        expect(sut, toCompleteSendWithError: .networkError(.posix(.ECANCELED))) {
            sut.disconnect()
        }
    }

    func test_send_noErrorGivesNoError() {
        let sut = makeSUT()
        expect(sut, toCompleteSendWithError: .none) { }
    }

    func test_receive_withErrorGivesError() {
        let sut = makeSUT()
        let request = makeRequest()

        sut.stateHandler = sendRequestOnReady(sut, request)

        expect(sut, toReceiveWith: failure(.networkError(.posix(.ECANCELED)))) {
            sut.disconnect()
        }
    }

    func test_receive_noErrorGivesData() {
        let sut = makeSUT()
        let request = makeRequest()
        let requestData = request.data(using: .utf8)!

        sut.stateHandler = sendRequestOnReady(sut, request)

        expect(sut, toReceiveWith: .success(requestData)) { }
    }

    func test_receiveTwice_canReceiveTwice() {
        let sut = makeSUT()
        let request = makeRequest()
        let requestData = request.data(using: .utf8)!
        let exp1 = expectation(description: "first result")
        let exp2 = expectation(description: "second result")
        

        var results = [Data]()
        sut.stateHandler = { _ in }

        try? sut.start()

        sut.send(message: request) { _ in }
        sut.receive { result in
            if let result = try? result.get() {
                results.append(result)
            }
            exp1.fulfill()
        }

        sut.send(message: request) { _ in }
        sut.receive { result in
            if let result = try? result.get() {
                results.append(result)
            }
            exp2.fulfill()
        }

        waitForExpectations(timeout: 2)

        XCTAssertEqual(results, [requestData, requestData])
    }

    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> WebSocketClient {
        let url = URL(string: "ws://127.0.0.1:8080")!
        let sut = NetworkConnectionWebSocketClient(url: url)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func expect(_ sut: WebSocketClient, toChangeToState expected: NWConnection.State, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        var state: NWConnection.State?

        let exp = expectation(description: "Wait for ready")

        sut.stateHandler = {
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

        XCTAssertEqual(state, expected)
    }

    private func expect(_ sut: WebSocketClient, toReceiveWith expected:  Result<Data, Error>, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for receive error")

        try? sut.start()

        action()

        sut.receive { result in
            switch (result, expected) {
            case let (.failure(capturedError), .failure(expectedError)):
                let capturedError = capturedError as? NetworkConnectionWebSocketClient.Error
                let expectedError = expectedError as? NetworkConnectionWebSocketClient.Error
                XCTAssertEqual(capturedError, expectedError)
            case let(.success(capturedData), .success(expectedData)):
                XCTAssertEqual(capturedData, expectedData)
            default:
                XCTFail("Expected \(expected), got \(result) instead.")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }

    func expect(_ sut: WebSocketClient, toCompleteSendWithError expectedError: NetworkConnectionWebSocketClient.Error?, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let request = makeRequest()
        let exp = expectation(description: "Wait for send completion")
        var error: NetworkConnectionWebSocketClient.Error?
        sut.stateHandler = { _ in }

        try? sut.start()

        action()

        sut.send(message: request) {
            error = $0 as? NetworkConnectionWebSocketClient.Error
            exp.fulfill()
        }
        if expectedError == .none {
            XCTExpectFailure {
                wait(for: [exp], timeout: 1)
            }
        } else {
            wait(for: [exp], timeout: 1)
        }

        XCTAssertEqual(error, expectedError)
    }

    private func failure(_ error: NetworkConnectionWebSocketClient.Error) -> Result<Data, Error> {
        .failure(error)
    }

    private func sendRequestOnReady(_ sut: WebSocketClient, _ request: String) -> (WebSocketDelegateState) -> Void {
        return { [weak sut] in
            if $0 == .ready {
                sut?.send(message: request, completion: { _ in })
            }
        }
    }

    private func makeRequest() -> String {
        let filter = Filter(kinds: [1], since: .now)
        let sub = "mySub"

        let request = ClientMessage.Message.request(sub: sub, filters: [filter])
        return ClientMessageMapper.mapMessage(request)
    }

    fileprivate func captureRecieveError(_ error: @escaping (Error?) -> Void, exp: XCTestExpectation) -> ((Result<Data, Error>) -> Void)? {
        return { result in
               switch result {
               case .failure(let capturedError):
                   error(capturedError)
                   break
               case .success:
                   break
               }
               exp.fulfill()
        }
    }

    fileprivate func attemptRecieveOnDisconnect(_ sut: WebSocketClient, _ request: String) -> (NWConnection.State) -> Void {
        return { [weak sut] in
            if $0 == .ready {
                sut?.disconnect()
                sut?.send(message: request, completion: { _ in }) }
        }
    }
}

