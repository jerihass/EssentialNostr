//
//  Created by Jericho Hasselbush on 5/18/24.
//

import XCTest
import EssentialNostr
import Network

final class EssentialNostrAPIEndToEndTests: XCTestCase {
    func test_endToEndTestServer_retrievesExpectedEvents() throws {

        let url = URL(string: "ws://127.0.0.1:8080")!
        let client = NetworkConnectionWebSocketClient(url: url)
        let delegate = Delegate()
        delegate.stateHandler = { _ in }
        client.delegate = delegate
        let loader = RemoteEventLoader(client: client)

        try client.start()
        loader.request("EVENT_REQUEST")
        var receivedResult: LoadEventResult?

        let exp = expectation(description: "Wait for load completion")
        loader.load { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3.0)

        switch receivedResult {
        case let .success(event)?:
            XCTAssertEqual(event.id, "id1")
        case let .failure(error)?:
            XCTFail("Expected at successful event result, got \(error) instead.")
        default:
            XCTFail("Expected successful event result, got no result instead.")
        }
    }

    class Delegate: WebSocketDelegate {
        var stateHandler: ((NWConnection.State) -> Void)?

    }
}
