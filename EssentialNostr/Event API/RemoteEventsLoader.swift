//
//  Created by Jericho Hasselbush on 6/8/24.
//

import Foundation

public class RemoteEventsLoader: EventsLoader {
    let eventLoader: EventLoader

    public init(eventLoader: EventLoader) {
        self.eventLoader = eventLoader
    }

    public func load(completion: @escaping (EventsLoader.LoadResult) -> Void) {
        var events = [Event]()

        var load: (_ : Result<Event?, Error>) -> Void = { _ in }

        load = { [weak self] result in
            
            guard let self = self else { return }
            switch result {
            case let .success(event):
                guard let event = event else { return completion(.success(events)) }
                events.append(event)
                eventLoader.load(load)
            case let .failure(error):
                if case RemoteEventLoader.Error.eose = error {
                    completion(.success(events))
                } else {
                    completion(.failure(error))
                }
                break
            }
        }

        eventLoader.load(load)
    }
}
