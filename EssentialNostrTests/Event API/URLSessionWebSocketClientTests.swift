//
//  Created by Jericho Hasselbush on 5/23/24.
//

import XCTest
import EssentialNostr

class URLSessionWebSocketClientTests: XCTestCase {
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

        expect(sut, toReceiveWith: .failure(URLSessionWebSocketClient.Error.receiveError)) {
            sut.disconnect()
        }
    }

    func test_receive_noErrorGivesData() throws {
        let (sut, _) = makeSUT()
        let request = makeRequest()
        let requestData = request.data(using: .utf8)!

        expect(sut, toReceiveWith: .success(requestData)) {
            sut.send(message: request, completion: { _ in })
        }
    }

    // MARK: - Helpers

    func makeSUT() -> (sut: URLSessionWebSocketClient, task: URLSession) {
        let url = URL(string: "ws://127.0.0.1:8080")!
        let session = URLSession(configuration: .ephemeral)
        let sut = URLSessionWebSocketClient(session: session, url: url)
        return (sut, session)
    }

    func expect(_ sut: URLSessionWebSocketClient, toCompleteSendWithError expectedError: URLSessionWebSocketClient.Error?, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let request = makeRequest()
        let exp = expectation(description: "Wait for send completion")
        var error: URLSessionWebSocketClient.Error?

        sut.start()

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

        sut.start()

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
