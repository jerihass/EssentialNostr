//
//  Created by Jericho Hasselbush on 6/8/24.
//

import XCTest
import EssentialNostr

class RemoteEventsLoader {

}

class LoadEventsFromRemoteTests: XCTestCase {
    func test_init_doesNotRequestLoadWhenCreated() {
        let eventLoader = RemoteLoaderSpy()
        let sut = RemoteEventsLoader()
        
        XCTAssertEqual(eventLoader.receivedMessages, [])
    }

    private class RemoteLoaderSpy: EventLoader {
        var receivedMessages = [String]()
        func request(_ message: String) {

        }
        
        func load(_ completion: @escaping (LoadEventResult) -> Void) {

        }
    }
}
