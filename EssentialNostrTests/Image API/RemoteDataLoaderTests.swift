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
        sut.load(url: url)

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURL() {
        let (sut, client) = makeSUT()

        let url = URL(string: "http://any-url.com/")!
        sut.load(url: url)
        sut.load(url: url)

        XCTAssertEqual(client.requestedURLs, [url, url])
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
        var requestedURLs = [URL]()
        func get(from url: URL) {
            requestedURLs.append(url)
        }
    }
}
