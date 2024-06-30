//
//  Created by Jericho Hasselbush on 6/30/24.
//

import XCTest
import EssentialNostr

class RemoteDataLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestsDataFromURL() {
        let (sut, client) = makeSUT()

        let url = URL(string: "http://any-url.com/")!
        sut.load(url: url) { _ in }

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURL() {
        let (sut, client) = makeSUT()

        let url = URL(string: "http://any-url.com/")!
        sut.load(url: url) { _ in }
        sut.load(url: url) { _ in }

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()

        let url = URL(string: "http://any-url.com/")!

        var capturedError: RemoteDataLoader.Error?
        sut.load(url: url) { error in
            capturedError = error
        }

        client.completeLoadWith(error: NSError(domain: "domain", code: 0))

        XCTAssertEqual(capturedError, RemoteDataLoader.Error.connectivity)
    }

    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()

        let url = URL(string: "http://any-url.com/")!

        [199, 201, 300, 400].enumerated().forEach { index, code in
            var capturedErrors = [RemoteDataLoader.Error?]()

            sut.load(url: url) { error in
                capturedErrors.append(error)
            }

            client.completeLoadWith(statusCode: code, at: index)

            XCTAssertEqual(capturedErrors, [.invalidData])
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: RemoteDataLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteDataLoader(client: client)
        trackForMemoryLeaks(client)
        trackForMemoryLeaks(sut)
        return (sut, client)
    }

    private class HTTPClientSpy: HTTPClient {
        private var requests = [(url: URL, completion: (HTTPClient.Result) -> Void)]()
        var requestedURLs: [URL] { requests.map(\.url) }

        func get(from url: URL, completion:  @escaping (HTTPClient.Result) -> Void) {
            requests.append((url, completion))
        }

        func completeLoadWith(error: Error, at index: Int = 0) {
            requests[index].completion(.failure(error))
        }

        func completeLoadWith(statusCode: Int, at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index], statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            requests[index].completion(.success(response))
        }
    }
}
