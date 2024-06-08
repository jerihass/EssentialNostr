//
//  Created by Jericho Hasselbush on 6/6/24.
//

import Foundation
import EssentialNostr

public class EventsViewModel {
    private let loader: EventLoader
    private(set) var events = [Event]()
    public init(loader: EventLoader) {
        self.loader = loader
    }

    public func refreshEvents() {
        loadEvents()
    }

    public func loadEvents() {
        let load: (_ completion: Result<Event, Error>) -> Void = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(event):
                events.append(event)
            case .failure:
                break
            }
        }

        loader.load(load)
    }
}
