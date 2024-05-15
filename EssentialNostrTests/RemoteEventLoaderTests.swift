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

        sut.load(request: request)

        XCTAssertEqual(client.requests, [request])
    }

    func test_loadTwice_requestEventFromClientTwice() {
        let request = "Some Request"
        let (sut, client) = makeSUT()

        sut.load(request: request)
        sut.load(request: request)

        XCTAssertEqual(client.requests, [request, request])
    }

    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        let request = "Some Request"
        client.error = NSError(domain: "", code: 0)
        var capturedErrors = [RemoteEventLoader.Error]()

        sut.load(request: request) { capturedErrors.append($0) }

        XCTAssertEqual(capturedErrors, [.connectivity])
    }

    // MARK: - Helpers

    func makeSUT() -> (sut: RemoteEventLoader, client: WebSocketClientSpy) {
        let client = WebSocketClientSpy()
        let sut = RemoteEventLoader(client: client)
        return (sut, client)
    }

    class WebSocketClientSpy: WebSocketClient {
        var requests = [String]()
        var error: Error?
        func receive(with request: String, completion: @escaping (Error) -> Void) {
            if let error = error {
                completion(error)
            }
            requests.append(request)
        }
    }
}
