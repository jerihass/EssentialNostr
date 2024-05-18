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

    func test_start_continuesToReadyStateOnGoodConnection() {
        let sut = makeSUT()
        var state: NWConnection.State?

        let exp = expectation(description: "Wait for ready")
        sut.delegate?.stateHandler = { s in
            if case .ready = s {
                state = s
                exp.fulfill()
            }
        }

        try? sut.start()

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(state, .ready)
    }

    func test_disconnect_cancelsConnection() {
        let sut = makeSUT()
        var state: NWConnection.State?

        let exp = expectation(description: "Wait for ready")
        sut.delegate?.stateHandler = { s in
            if case .cancelled = s {
                state = s
                exp.fulfill()
            }
        }

        try? sut.start()

        sut.disconnect()

        wait(for: [exp], timeout: 0.2)

        XCTAssertEqual(state, .cancelled)
    }

    func test_send_noErrorGivesNoError() {
        let sut = makeSUT()
        var caughtError: NetworkConnectionWebSocketClient.Error?

        let request = makeRequest()

        let errorExp = expectation(description: "Expect no error")

        sut.delegate?.stateHandler = { [weak sut] in
            if $0 == .ready { sut?.send(message: request, completion: {
                if case let error = $0 {
                    caughtError = error as? NetworkConnectionWebSocketClient.Error
                }
                errorExp.fulfill()
            }) }
        }


        try? sut.start()

        XCTExpectFailure {
            wait(for: [errorExp], timeout: 1)
        }

        XCTAssertNil(caughtError)
    }

    func test_send_withErrorGivesError() {
        let sut = makeSUT()
        let request = makeRequest()

        var error: NetworkConnectionWebSocketClient.Error?
        let exp = expectation(description: "Wait for send error")

        sut.delegate?.stateHandler = { [weak sut] in
            if $0 != .cancelled {
                sut?.disconnect()
                sut?.send(message: request) { gotError in
                    error = gotError as? NetworkConnectionWebSocketClient.Error
                    exp.fulfill()
                }
            }
        }

        try? sut.start()

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(error, .networkError(.posix(.ECANCELED)))
    }

    func test_receive_withErrorGivesError() {
        let sut = makeSUT()
        let request = makeRequest()

        var error: NetworkConnectionWebSocketClient.Error?
        let exp = expectation(description: "Wait for receive error")

        sut.delegate?.stateHandler = { [weak sut] in
            if $0 == .ready {
                sut?.send(message: request, completion: { _ in })
            }
        }

        try? sut.start()

        sut.disconnect()

        sut.receive { result in
            switch result {
            case .failure(let capturedError):
                error = capturedError as? NetworkConnectionWebSocketClient.Error
                break
            case .success:
                break
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(error, .networkError(.posix(.ECANCELED)))
    }

    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> WebSocketClient {
        let url = URL(string: "wss://127.0.0.1:8080")!
        let sut = NetworkConnectionWebSocketClient(url: url)
        let delegate = DelegateSpy()
        sut.delegate = delegate
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(delegate, file: file, line: line)
        return sut
    }

    private class DelegateSpy: WebSocketDelegate {
        var stateHandler: ((NWConnection.State) -> Void)?
    }

    private func makeRequest() -> String {
        "Request"
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

struct Weak<T> {
    var object: T? {
        get { storage as? T }
        set { storage = newValue as AnyObject }
    }

    weak private var storage: AnyObject?

    init(_ stored: T) {
        self.object = stored
    }
}
