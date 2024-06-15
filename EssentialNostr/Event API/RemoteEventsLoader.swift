//
//  Created by Jericho Hasselbush on 6/8/24.
//

import Foundation

public typealias EventHandler = (Event) -> Void

public class RemoteEventsLoader: FeedLoader {
    let eventLoader: EventLoader
    let eventHandler: EventHandler
    private var events = [Event]()

    public init(eventHandler: @escaping EventHandler = { _ in }, eventLoader: EventLoader) {
        self.eventHandler = eventHandler
        self.eventLoader = eventLoader
    }

    public func load(completion: @escaping (FeedLoader.LoadResult) -> Void) {

        var load: (_ : Result<Event?, Error>) -> Void = { _ in }

        load = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(event):
                guard let event = event else {
                    completion(.success(events))
                    return events = []
                }
                eventHandler(event)
                events.append(event)
                eventLoader.load(load)
            case let .failure(error):
                if case RemoteEventLoader.Error.eose = error {
                    completion(.success(events))
                    events = []
                    eventLoader.load(load)
                } else {
                    completion(.failure(error))
                }
                break
            }
        }

        eventLoader.load(load)
    }
}
