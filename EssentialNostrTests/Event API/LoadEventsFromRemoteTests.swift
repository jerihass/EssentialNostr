//
//  Created by Jericho Hasselbush on 6/8/24.
//

import XCTest
import EssentialNostr

class RemoteEventsLoader {
    let eventLoader: EventLoader

    init(eventLoader: EventLoader) {
        self.eventLoader = eventLoader
    }

    func load() {
        eventLoader.load { _ in }
    }
}

class LoadEventsFromRemoteTests: XCTestCase {
    func test_init_doesNotRequestLoadWhenCreated() {
        let eventLoader = RemoteLoaderSpy()
        let sut = RemoteEventsLoader(eventLoader: eventLoader)

        XCTAssertEqual(eventLoader.receivedMessages, [])
    }

    func test_load_requestsEvents() {
        let eventLoader = RemoteLoaderSpy()
        let sut = RemoteEventsLoader(eventLoader: eventLoader)

        sut.load()

        XCTAssertEqual(eventLoader.receivedMessages, [.loadEvents])
    }


    // MARK: - Helpers


    private class RemoteLoaderSpy: EventLoader {
        enum Message {
            case loadEvents
        }
        var receivedMessages = [Message]()
        func request(_ message: String) {

        }
        
        func load(_ completion: @escaping (LoadEventResult) -> Void) {
            receivedMessages.append(.loadEvents)
        }
    }
}
