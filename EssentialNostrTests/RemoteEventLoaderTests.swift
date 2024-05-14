//
//  Created by Jericho Hasselbush on 5/14/24.
//

import XCTest

class RemoteEventLoader {
    var client: WebSocketClient

    init(client: WebSocketClient) {
        self.client = client
    }

    func load() {
        client.request = "REQ"
    }
}

class WebSocketClient {
    var request: String?
}

class RemoteEventLoaderTests: XCTestCase {
    func test_init_doesNotRequestWhenCreated() {
        let client = WebSocketClient()
        _ = RemoteEventLoader(client: client)

        XCTAssertNil(client.request)
    }

    func test_load_requestEventFromClient() {
        let client = WebSocketClient()
        let sut = RemoteEventLoader(client: client)

        sut.load()

        XCTAssertNotNil(client.request)
    }
}
