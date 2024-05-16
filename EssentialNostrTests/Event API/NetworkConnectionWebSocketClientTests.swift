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

        let exp = expectation(description: "Wait for ready")

        sut.stateHandler = { [weak sut] in
            if $0 == .ready { sut?.receive(with: request) }
        }

        sut.receiveHandler = {
            echo = $0
            exp.fulfill()
        }

        try? sut.start()

        wait(for: [exp], timeout: 0.2)

        XCTAssertEqual(echo, data)
    }

    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> NetworkConnectionWebSocketClient {
        let url = URL(string: "wss://127.0.0.1:8080")!
        let sut = NetworkConnectionWebSocketClient(url: url)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
