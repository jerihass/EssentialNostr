//
//  Created by Jericho Hasselbush on 5/14/24.
//

import XCTest
import EssentialNostr

class RemoteEventLoaderTests: XCTestCase {
    func test_init_doesNotRequestWhenCreated() {
        let (_, client) = makeSUT()

        XCTAssertTrue(client.requests.isEmpty)
    }

    func test_load_requestEventFromClient() {
        let request = "Some Request"
        let (sut, client) = makeSUT()

        sut.load(request: request) { _ in }

        XCTAssertEqual(client.requests, [request])
    }

    func test_loadTwice_requestEventFromClientTwice() {
        let request = "Some Request"
        let (sut, client) = makeSUT()

        sut.load(request: request) { _ in }
        sut.load(request: request) { _ in }

        XCTAssertEqual(client.requests, [request, request])
    }

    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .connectivity) {
            let clientError = NSError(domain: "", code: 0)
            client.complete(with: clientError)
        }
    }

    func test_load_deliversErrorOnClosedResponse() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .closed) {
            let closedMessage = Data("[\"CLOSED\",\"sub1\",\"duplicate: sub1 already opened\"]".utf8)
            client.complete(with: closedMessage)
        }
    }

    func test_load_deliversErrorOnEventResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .invalidData) {
            let closedMessage = Data("[\"EVENT\",\"sub1\",\"INVALID_event_JSON\"]".utf8)
            client.complete(with: closedMessage)
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: RemoteEventLoader, client: WebSocketClientSpy) {
        let client = WebSocketClientSpy()
        let sut = RemoteEventLoader(client: client)
        return (sut, client)
    }

    private func expect(_ sut: RemoteEventLoader, toCompleteWith error: RemoteEventLoader.Error, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let request = "Some Request"
        var capturedErrors = [RemoteEventLoader.Error]()

        sut.load(request: request) { capturedErrors.append($0) }

        action()

        XCTAssertEqual(capturedErrors, [error])
    }

    class WebSocketClientSpy: WebSocketClient {
        var allRequests = [(request: String, completion: (Result<Data, Error>) -> Void)]()
        var requests: [String] { allRequests.map { $0.request }}
        func receive(with request: String, completion: @escaping (Result<Data, Error>) -> Void) {
            allRequests.append((request, completion))
        }

        func complete(with error: Error, at index: Int = 0) {
            allRequests[index].completion(.failure(error))
        }

        func complete(with message: Data, at index: Int = 0) {
            allRequests[index].completion(.success(message))
        }
    }
}
