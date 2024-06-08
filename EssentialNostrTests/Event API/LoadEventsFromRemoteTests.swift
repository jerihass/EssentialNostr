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

    func load(completion: @escaping (EventsLoader.LoadResult) -> Void) {
        eventLoader.load { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case .success(_):
                break
            }
        }
    }
}

class LoadEventsFromRemoteTests: XCTestCase {
    func test_init_doesNotRequestLoadWhenCreated() {
        let (_, eventLoader) = makeSUT()

        XCTAssertEqual(eventLoader.receivedMessages, [])
    }

    func test_load_requestsEvents() {
        let (sut, eventLoader) = makeSUT()

        sut.load() { _ in }

        XCTAssertEqual(eventLoader.receivedMessages, [.loadEvents])
    }

    func test_load_givesErrorOnLoaderError() {
        let (sut, eventLoader) = makeSUT()

        let error = anyError()
        let exp = expectation(description: "Wait for load completion")
        sut.load { result in
            switch result {
            case .success(_):
                XCTFail()
            case let .failure(receivedError as NSError?):
                XCTAssertEqual(receivedError, error)
            }
            exp.fulfill()
        }

        eventLoader.complete(with: error)

        wait(for: [exp], timeout: 1)
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
        var loadCompletions = [(LoadEventResult) -> Void]()
        func request(_ message: String) {

        }
        
        func load(_ completion: @escaping (LoadEventResult) -> Void) {
            receivedMessages.append(.loadEvents)
            loadCompletions.append(completion)
        }

        func complete(with error: Error, at index: Int = 0) {
            loadCompletions[index](.failure(error))
        }
    }
}
