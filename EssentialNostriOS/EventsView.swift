//
//  Created by Jericho Hasselbush on 6/8/24.
//

import SwiftUI
import EssentialNostr

struct EventsView: View {
    var viewModel: EventsViewModel
    @State var events = [Event]()
    var body: some View {
        Text("Nostr Events")
            .font(.title)
        List(events, id:\.id) { event in
            EventView(event: event)
        }
        .listStyle(.plain)
        .refreshable {
            events = await viewModel.fetchEvents()
        }
    }

}

extension EventsViewModel {
    func fetchEvents() async -> [Event] {
        await withCheckedContinuation { [weak self] continuation in
            DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
                self?.loadEvents()
                continuation.resume(with: .success(self?.events ?? []))
            }
        }
    }
}

#Preview {
    class PreviewLoader: EventsLoader {
        let events:[Event] = [
            Event(id: "eventID1", publicKey: "pubkey1", created: .now, kind: 1, tags: [], content: "contents some 1", signature: "sig1"),
            Event(id: "eventID2", publicKey: "pubkey2", created: .now, kind: 1, tags: [], content: "contents some 2", signature: "sig2"),
            Event(id: "eventID3", publicKey: "pubkey3", created: .now, kind: 1, tags: [], content: "contents some 3", signature: "sig3"),
            Event(id: "eventID4", publicKey: "pubkey4", created: .now, kind: 1, tags: [], content: "contents some 4", signature: "sig4")
        ]

        func load(completion: @escaping (LoadResult) -> Void) {
            completion(.success(self.events))
        }
    }

    let previewLoader = PreviewLoader()
    let vm = EventsViewModel(loader: previewLoader)

    return EventsView(viewModel: vm)
}
