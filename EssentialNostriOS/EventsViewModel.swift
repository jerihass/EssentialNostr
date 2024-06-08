//
//  Created by Jericho Hasselbush on 6/6/24.
//

import Foundation
import EssentialNostr

public class EventsViewModel {
    private let loader: EventsLoader
    private(set) var events = [Event]()
    public init(loader: EventsLoader) {
        self.loader = loader
    }

    public func refreshEvents() {
        loadEvents()
    }

    public func loadEvents() {
        var load: (_ completion: Result<[Event], Error>) -> Void  = { _ in }

        load = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(events):
                self.events = events
                loader.load(completion: load)
            case .failure:
                break
            }
        }

        loader.load(completion: load)
    }
}
