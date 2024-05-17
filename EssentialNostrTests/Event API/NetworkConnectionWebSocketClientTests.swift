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
        let sut: NetworkConnectionWebSocketClient = makeSUT()
        var echo: Data?
        let request = "Request"
        let data = request.data(using: .utf8)!

        let exp = expectation(description: "Wait for receive data")

        sut.stateHandler = { [weak sut] in
            if $0 == .ready { sut?.receive(with: request, completion: { _ in }) }
        }

        sut.receiveHandler = {
            echo = try? $0.get()
            exp.fulfill()
        }

        try? sut.start()

        wait(for: [exp], timeout: 0.2)

        XCTAssertEqual(echo, data)
    }

    func test_receive_sendErrorGivesError() {
        let sut: NetworkConnectionWebSocketClient = makeSUT()
        let request = "Request"

        var error: NetworkConnectionWebSocketClient.Error?

        let exp = expectation(description: "Wait for send error")
        sut.stateHandler = sendOnDisconnect(sut, request, { error = $0 }, exp)
        sut.receiveHandler = { _ in }

        try? sut.start()

        wait(for: [exp], timeout: 0.2)

        XCTAssertEqual(error, .networkError(.posix(.ECANCELED)))
    }

    func test_receive_errorGivesError() {
        let sut: NetworkConnectionWebSocketClient = makeSUT()
        let request = "Request"

        var error: NetworkConnectionWebSocketClient.Error?

        sut.stateHandler = recieveOnDisconnect(sut, request)

        let exp = expectation(description: "Wait for receive error")
        sut.receiveHandler = captureRecieveError({ error = $0 }, exp: exp)

        try? sut.start()

        wait(for: [exp], timeout: 0.2)

        XCTAssertEqual(error, .networkError(.posix(.ECANCELED)))
    }

    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> NetworkConnectionWebSocketClient {
        let url = URL(string: "wss://127.0.0.1:8080")!
        let sut = NetworkConnectionWebSocketClient(url: url)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    fileprivate func captureRecieveError(_ error: @escaping (NetworkConnectionWebSocketClient.Error?) -> Void, exp: XCTestExpectation) -> ((Result<Data, NetworkConnectionWebSocketClient.Error>) -> Void)? {
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

    fileprivate func sendOnDisconnect(_ sut: NetworkConnectionWebSocketClient, _ request: String, _ error: @escaping (NetworkConnectionWebSocketClient.Error?) -> Void , _ exp: XCTestExpectation) -> (NWConnection.State) -> Void {
        return { [weak sut] in
            sut?.disconnect()
            if $0 == .cancelled { sut?.receive(with: request, completion: {
                error($0)
                exp.fulfill()
            }) }
        }
    }

    fileprivate func recieveOnDisconnect(_ sut: NetworkConnectionWebSocketClient, _ request: String) -> (NWConnection.State) -> Void {
        return { [weak sut] in
            if $0 == .ready {
                sut?.disconnect()
                sut?.receive(with: request, completion: { _ in }) }
        }
    }
}
