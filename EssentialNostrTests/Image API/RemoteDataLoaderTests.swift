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

        expect(sut: sut, toCompleteWith: .failure(.connectivity)) {
            client.completeLoadWith(error: NSError(domain: "domain", code: 0))
        }
    }

    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()

        [199, 201, 300, 400].enumerated().forEach { index, code in
            expect(sut: sut, toCompleteWith: .failure(.invalidData)) {
                client.completeLoadWith(statusCode: code, at: index)
            }
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

    private func expect(sut: RemoteDataLoader, toCompleteWith expected: RemoteDataLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let url = URL(string: "http://any-url.com/")!
        let exp = expectation(description: "Wait for load completion")

        sut.load(url: url) { result in
            switch (result, expected) {
            case let (.success(data), .success(expData)):
                XCTAssertEqual(data, expData)
            case let (.failure(error), .failure(expFailure)):
                XCTAssertEqual(error, expFailure)
            default:
                XCTFail("Expected: \(expected), got \(result) instead.")
            }
            exp.fulfill()
        }

        action()

        waitForExpectations(timeout: 1)
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

        func completeLoadWith(statusCode: Int, data: Data? = nil, at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index], statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            requests[index].completion(.success(response))
        }
    }
}
