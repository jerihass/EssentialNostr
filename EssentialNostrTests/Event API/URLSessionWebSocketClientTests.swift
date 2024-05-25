//
//  Created by Jericho Hasselbush on 5/23/24.
//

import XCTest
import EssentialNostr

struct URLSessionWSDelegate: WebSocketDelegate {
    var stateHandler: ((EssentialNostr.WebSocketDelegateState) -> Void)?
}

class URLSessionWebSocketClient {
    let url: URL
    let session: URLSession
    var delegate: URLSessionWSDelegate?

    public enum Error: Swift.Error, Equatable {
        case stateHandlerNotSet
    }

    init(session: URLSession, url: URL) {
        self.session = session
        self.url = url
    }

    func start() throws {
        guard let stateHandler = delegate?.stateHandler else { throw Error.stateHandlerNotSet }
        stateHandler(.ready)
        _ = session.webSocketTask(with: url)
    }

    func disconnect() {
        delegate?.stateHandler?(.cancelled)
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
    // MARK: - Helpers

    func makeSUT() -> (sut: URLSessionWebSocketClient, task: URLSession) {
        let url = URL(string: "wss://127.0.0.1/")!
        let session = URLSession(configuration: .ephemeral)
        let sut = URLSessionWebSocketClient(session: session, url: url)
        let delegate = URLSessionWSDelegate()
        sut.delegate = delegate
        return (sut, session)
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
}
