//
//  Created by Jericho Hasselbush on 6/6/24.
//

import Foundation
import EssentialNostr

@Observable
public class EventsViewModel {
    private let loader: EventsLoader
    private(set) var events = [Event]()
    private(set) public var isRefreshing: Bool = false
    public init(loader: EventsLoader) {
        self.loader = loader
    }

    public func refreshEvents() {
        loadEvents()
    }

    public func loadEvents() {
        isRefreshing = true
        loader.load() { [weak self] result in
            guard let self = self else { return }
            self.events = (try? result.get()) ?? []
            isRefreshing = false
        }
    }
}
