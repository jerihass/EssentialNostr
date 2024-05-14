//
//  Created by Jericho Hasselbush on 5/14/24.
//

import XCTest

class RemoteEventLoader {

}

class WebSocketClient {
    var request: String?
}

class RemoteEventLoaderTests: XCTestCase {
    func test_init_doesNotRequestWhenCreated() {
        let client = WebSocketClient()
        _ = RemoteEventLoader()

        XCTAssertNil(client.request)
    }
}
