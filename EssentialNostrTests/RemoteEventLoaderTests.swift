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
        client.receive(from: "REQ")
    }
}

protocol WebSocketClient {
    func receive(from request: String)
}

class WebSocketClientSpy: WebSocketClient {
    var request: String?
    func receive(from request: String) {
        self.request = request
    }
}

class RemoteEventLoaderTests: XCTestCase {
    func test_init_doesNotRequestWhenCreated() {
        let client = WebSocketClientSpy()
        _ = RemoteEventLoader(client: client)

        XCTAssertNil(client.request)
    }

    func test_load_requestEventFromClient() {
        let client = WebSocketClientSpy()
        let sut = RemoteEventLoader(client: client)

        sut.load()

        XCTAssertNotNil(client.request)
    }
}
