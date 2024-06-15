//
//  Created by Jericho Hasselbush on 6/8/24.
//

import Foundation

protocol EventStream {
    var eventHandler: (Event) -> Void { get }
    func load(completion: @escaping (Error?) -> Void)
}

public typealias EventHandler = (Event) -> Void

public class RemoteFeedLoader: EventStream {
    let eventLoader: EventLoader
    let eventHandler: EventHandler

    public init(eventHandler: @escaping EventHandler = { _ in }, eventLoader: EventLoader) {
        self.eventHandler = eventHandler
        self.eventLoader = eventLoader
    }

    public func load(completion: @escaping (Error?) -> Void) {

        var load: (_ : Result<Event?, Error>) -> Void = { _ in }

        load = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(event):
                guard let event = event else { return }
                eventHandler(event)
                eventLoader.load(load)
            case let .failure(error):
                if case RemoteEventLoader.Error.eose = error {
                    eventLoader.load(load)
                } else {
                    completion(error)
                }
            }
        }

        eventLoader.load(load)
    }
}
