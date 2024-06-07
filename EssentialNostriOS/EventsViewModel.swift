//
//  Created by Jericho Hasselbush on 6/6/24.
//

import Foundation
import EssentialNostr

public class EventsViewModel {
    private let loader: EventsLoader
    private(set) public var isRefreshing: Bool = false
    public init(loader: EventsLoader) {
        self.loader = loader
    }

    public func refreshEvents() {
        loadEvents()
    }

    public func loadEvents() {
        isRefreshing = true
        loader.load() { [weak self] _ in
            guard let self = self else { return }
            isRefreshing = false
        }
    }
}
