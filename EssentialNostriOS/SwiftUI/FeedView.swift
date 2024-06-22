//
//  Created by Jericho Hasselbush on 6/8/24.
//

import SwiftUI
import EssentialNostr

public struct FeedViewModel {
    private(set) var events = [EventModel]()
    private let eventSource: () -> [EventModel]

    public init(eventSource: @escaping () -> [EventModel]) {
        self.eventSource = eventSource
    }

    mutating func fetchEvents() {
        events = eventSource()
    }
}

public struct FeedView: View {
    @State private var model: FeedViewModel
    private let titleView: TitleView
    private let errorView: ErrorView

    public init(viewModel: FeedViewModel, titleView: TitleView, errorView: ErrorView) {
        self.model = viewModel
        self.titleView = titleView
        self.errorView = errorView
    }

    public var body: some View {
        titleView

        errorView

        List(model.events, id:\.id) { model in
            EventView(model: model)
        }
        .listStyle(.plain)
        .task(fetch)
        .refreshable(action: fetch)
    }

    @Sendable func fetch() async {
        model.fetchEvents()
    }
}

#Preview {
    let events:[Event] = [
        Event(id: "eventID1", publicKey: "pubkey1", created: .distantFuture, kind: 1, tags: [], content: "contents some 1", signature: "sig1"),
        Event(id: "eventID2", publicKey: "pubkey2", created: .now, kind: 1, tags: [], content: "contents some 2", signature: "sig2"),
        Event(id: "eventID3", publicKey: "pubkey3", created: .now - 314159268, kind: 1, tags: [], content: "contents some 3", signature: "sig3"),
        Event(id: "eventID4", publicKey: "pubkey4", created: .distantPast, kind: 1, tags: [], content: "contents some 4", signature: "sig4")
    ]
    let viewModel = FeedViewModel(eventSource: { events.map(EventModel.init) })
    let titleView = TitleView(model: .init())
    let errorModel = ErrorViewModel(message: {"Error"})
    let errorView = ErrorView(model: errorModel)
    return FeedView(viewModel: viewModel, titleView: titleView, errorView: errorView)
}
