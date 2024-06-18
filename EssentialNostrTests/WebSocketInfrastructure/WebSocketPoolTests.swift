//
//  Created by Jericho Hasselbush on 6/18/24.
//

import XCTest

class WebSocketPool {

}

class WebSocketPoolTests: XCTestCase {
    func test_init_poolDoesNotSendMessagesToPool() {
        let sut = WebSocketPool()
        let pool = PoolSpy()

        XCTAssertTrue(pool.receivedMessages.isEmpty)
    }

    private class PoolSpy {
        var receivedMessages = [Any]()
    }
}
