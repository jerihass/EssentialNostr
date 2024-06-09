//
//  Created by Jericho Hasselbush on 6/8/24.
//

import SwiftUI
import EssentialNostr

public struct EventsView: View {
    @State private var eventModels = [EventModel]()

    var fetchEvents: () -> [EventModel]

    public init(fetchEvents: @escaping () -> [EventModel]) {
        self.fetchEvents = fetchEvents
    }

    public var body: some View {
        Text("Nostr Events")
            .font(.title)
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

private class EventModelAdapter {
    static func models(_ events: [Event]) -> [EventModel] {
        events.map(EventModel.init)
    }
}

extension EventsViewModel {
    public func fetchEvents() async -> [Event] {
        await withCheckedContinuation { [weak self] continuation in
            guard let self = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
                guard let self = self else { return }
                self.loadEvents()
                continuation.resume(returning:self.events)
            }
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

    class PreviewLoader: EventsLoader {
        let events:[Event] = [
            Event(id: "eventID1", publicKey: "pubkey1", created: .now, kind: 1, tags: [], content: "contents some 1", signature: "sig1"),
            Event(id: "eventID2", publicKey: "pubkey2", created: .now, kind: 1, tags: [], content: "contents some 2", signature: "sig2"),
            Event(id: "eventID3", publicKey: "pubkey3", created: .now, kind: 1, tags: [], content: "contents some 3", signature: "sig3"),
            Event(id: "eventID4", publicKey: "pubkey4", created: .now, kind: 1, tags: [], content: "contents some 4", signature: "sig4")
        ]

        func request(_ message: String) {

        }

        func load(completion: @escaping (LoadResult) -> Void) {
            completion(.success(events))
        }
    }

    let previewLoader = PreviewLoader()
    let vm = EventsViewModel(loader: previewLoader)

    return EventsView {
        EventModelAdapter.models(events)
    }
}
