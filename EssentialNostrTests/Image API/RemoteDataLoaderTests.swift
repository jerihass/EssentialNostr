//
//  Created by Jericho Hasselbush on 6/30/24.
//

import XCTest

class RemoteDataLoader {

}

class HTTPClient {
    var requestedURL: URL?
}

class RemoteDataLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClient()
        _ = RemoteDataLoader()

        XCTAssertNil(client.requestedURL)
    }
}
