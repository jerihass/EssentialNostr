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
        loader.load() { [weak self] result in
            guard let self = self else { return }
            self.events = (try? result.get()) ?? []
        }
    }
}
