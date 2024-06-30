//
//  Created by Jericho Hasselbush on 6/30/24.
//

import XCTest

class RemoteDataLoader {
    let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func load(url: URL) {
        client.requestedURL = url
    }
}

class HTTPClient {
    var requestedURL: URL?
    func get(from url: URL) {
        requestedURL = url
    }
}

class RemoteDataLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClient()
        _ = RemoteDataLoader(client: client)

        XCTAssertNil(client.requestedURL)
    }

    func test_load_requestDataFromURL() {
        let client = HTTPClient()
        let sut = RemoteDataLoader(client: client)
        let url = URL(string: "http://any-url.com/")!
        sut.load(url: url)

        XCTAssertEqual(client.requestedURL, url)
    }
}
