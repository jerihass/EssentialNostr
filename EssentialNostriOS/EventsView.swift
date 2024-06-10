//
//  Created by Jericho Hasselbush on 6/8/24.
//

import SwiftUI
import EssentialNostr

public struct TitleViewModel {
    let title: String
}

public struct TitleView: View {
    private let model: TitleViewModel
    
    public init(model: TitleViewModel) {
        self.model = model
    }

    public var body: some View {
        Text(model.title)
            .font(.title)
    }
}

public struct EventsView: View {
    @State private var eventModels = [EventModel]()
    private let fetchEvents: () -> [EventModel]
    private let errorView: ErrorView
    private let titleView: TitleView
    public init(titleView: TitleView, errorView: ErrorView, fetchEvents: @escaping () -> [EventModel]) {
        self.titleView = titleView
        self.fetchEvents = fetchEvents
        self.errorView = errorView
    }

    public var body: some View {
        titleView

        errorView

        List(eventModels, id:\.id) { model in
            EventView(model: model)
        }
        .listStyle(.plain)
        .task(fetch)
        .refreshable(action: fetch)
    }

    @Sendable private func fetch() async {
        Task {
            eventModels = fetchEvents()
        }
    }
}

#Preview {
    let events:[Event] = [
        Event(id: "eventID1", publicKey: "pubkey1", created: .now, kind: 1, tags: [], content: "contents some 1", signature: "sig1"),
        Event(id: "eventID2", publicKey: "pubkey2", created: .now, kind: 1, tags: [], content: "contents some 2", signature: "sig2"),
        Event(id: "eventID3", publicKey: "pubkey3", created: .now, kind: 1, tags: [], content: "contents some 3", signature: "sig3"),
        Event(id: "eventID4", publicKey: "pubkey4", created: .now, kind: 1, tags: [], content: "contents some 4", signature: "sig4")
    ]
    let titleView = TitleView(model: .init(title: "Nostr Events"))
    let errorModel = ErrorViewModel(message: "Error")
    let errorView = ErrorView(model: errorModel)
    return EventsView(titleView: titleView, errorView: errorView) {
        events.map(EventModel.init)
    }
}
