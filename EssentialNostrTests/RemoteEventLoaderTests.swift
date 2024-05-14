//
//  Created by Jericho Hasselbush on 5/14/24.
//

import XCTest

// Request: ["REQ", <subscription_id>, <filters1>, <filters2>, ...]
// filterX JSON object:
//{
//  "ids": <a list of event ids>,
//  "authors": <a list of lowercase pubkeys, the pubkey of an event must be one of these>,
//  "kinds": <a list of a kind numbers>,
//  "#<single-letter (a-zA-Z)>": <a list of tag values, for #e — a list of event ids, for #p — a list of pubkeys, etc.>,
//  "since": <an integer unix timestamp in seconds, events must be newer than this to pass>,
//  "until": <an integer unix timestamp in seconds, events must be older than this to pass>,
//  "limit": <maximum number of events relays SHOULD return in the initial query>
//}

class RemoteEventLoader {
    var client: WebSocketClient

    init(client: WebSocketClient) {
        self.client = client
    }

    func load(request: String) {
        client.receive(with: request)
    }
}

protocol WebSocketClient {
    func receive(with request: String)
}


class RemoteEventLoaderTests: XCTestCase {
    func test_init_doesNotRequestWhenCreated() {
        let (_, client) = makeSUT()

        XCTAssertNil(client.request)
    }

    func test_load_requestEventFromClient() {
        let request = "Some Request"
        let (sut, client) = makeSUT()

        sut.load(request: request)

        XCTAssertEqual(client.request, request)
    }

    // MARK: - Helpers

    func makeSUT() -> (sut: RemoteEventLoader, client: WebSocketClientSpy) {
        let client = WebSocketClientSpy()
        let sut = RemoteEventLoader(client: client)
        return (sut, client)
    }

    class WebSocketClientSpy: WebSocketClient {
        var request: String?
        func receive(with request: String) {
            self.request = request
        }
    }
}
