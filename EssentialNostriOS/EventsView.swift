//
//  Created by Jericho Hasselbush on 6/8/24.
//

import SwiftUI
import EssentialNostr

struct EventsView: View {
    @State var events = [Event]()
    var viewModel: EventsViewModel

    var body: some View {
        Text("Nostr Events")
            .font(.title)
        List(events, id:\.id) { event in
            EventView(event: event)
        }
        .listStyle(.plain)
        .task(fetchEvents)
        .refreshable(action: fetchEvents)
    }

    @Sendable private func fetchEvents() async {
        events = await viewModel.fetchEvents()
    }
}

extension EventsViewModel {
    public func fetchEvents() async -> [Event] {
        await withCheckedContinuation { [weak self] continuation in
            guard let self = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
                guard let self = self else { return }
                self.loadEvents()
                continuation.resume(with: .success(self.events))
            }
        }
    }
}

#Preview {
    class PreviewLoader: EventLoader {
        let events:[Event] = [
            Event(id: "eventID1", publicKey: "pubkey1", created: .now, kind: 1, tags: [], content: "contents some 1", signature: "sig1"),
            Event(id: "eventID2", publicKey: "pubkey2", created: .now, kind: 1, tags: [], content: "contents some 2", signature: "sig2"),
            Event(id: "eventID3", publicKey: "pubkey3", created: .now, kind: 1, tags: [], content: "contents some 3", signature: "sig3"),
            Event(id: "eventID4", publicKey: "pubkey4", created: .now, kind: 1, tags: [], content: "contents some 4", signature: "sig4")
        ]

        func request(_ message: String) {

        }

        func load(_ completion: @escaping (LoadEventResult) -> Void) {
            for event in events {
                completion(.success(event))
            }
        }
    }

    let previewLoader = PreviewLoader()
    let vm = EventsViewModel(loader: previewLoader)

    return EventsView(viewModel: vm)
}
