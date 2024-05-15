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
        let request = "Some Request"
        let clientError = NSError(domain: "", code: 0)
        var capturedErrors = [RemoteEventLoader.Error]()

        sut.load(request: request) { capturedErrors.append($0) }
        client.complete(with: clientError)

        XCTAssertEqual(capturedErrors, [.connectivity])
    }

    func test_load_deliversErrorOnClosedResponse() {
        let (sut, client) = makeSUT()
        let request = "Some Request"
        var capturedErrors = [RemoteEventLoader.Error]()

        sut.load(request: request) { capturedErrors.append($0) }
        client.complete(withClosed: "[\"CLOSED\",\"sub1\",\"duplicate: sub1 already opened\"]")

        XCTAssertEqual(capturedErrors, [.closed])
    }

    // MARK: - Helpers

    func makeSUT() -> (sut: RemoteEventLoader, client: WebSocketClientSpy) {
        let client = WebSocketClientSpy()
        let sut = RemoteEventLoader(client: client)
        return (sut, client)
    }

    class WebSocketClientSpy: WebSocketClient {
        var allRequests = [(request: String, completion: (Result<String, Error>) -> Void)]()
        var requests: [String] { allRequests.map { $0.request }}
        func receive(with request: String, completion: @escaping (Result<String, Error>) -> Void) {
            allRequests.append((request, completion))
        }

        func complete(with error: Error, at index: Int = 0) {
            allRequests[index].completion(.failure(error))
        }

        func complete(withClosed message: String, at index: Int = 0) {
            allRequests[index].completion(.success(message))
        }
    }
}
