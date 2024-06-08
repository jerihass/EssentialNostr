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
        let (_, eventLoader) = makeSUT()

        XCTAssertEqual(eventLoader.receivedMessages, [])
    }

    func test_load_requestsEvents() {
        let (sut, eventLoader) = makeSUT()

        sut.load()

        XCTAssertEqual(eventLoader.receivedMessages, [.loadEvents])
    }


    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: RemoteEventsLoader, loader: RemoteLoaderSpy) {
        let loader = RemoteLoaderSpy()
        let sut = RemoteEventsLoader(eventLoader: loader)
        trackForMemoryLeaks(loader)
        trackForMemoryLeaks(sut)
        return (sut, loader)
    }

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
