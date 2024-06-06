//
//  Created by Jericho Hasselbush on 6/2/24.
//

import SwiftUI

struct NostrEventViewModel: Identifiable {
    var id = UUID()

    let npub: String
    let content: String
    let date: String
    let time: String
}

struct ContentView: View {
    private let nostrEvents = NostrEventViewModel.prototypeEvents
    var body: some View {
        Text("Nostr Events")
            .font(.title)

        List(nostrEvents) { event in
            noteView(event)
        }
        .listStyle(.plain)
    }

    private func noteView(_ model: NostrEventViewModel) -> some View {
        return Group {
            HStack {
                ZStack {
                    RoundedRectangle(cornerSize: .init(width: 8.0, height: 8.0), style: .continuous)
                        .frame(width: 48, height: 48)
                        .foregroundStyle(.ultraThinMaterial)
                    Image(systemName: "person.fill")
                        .frame(width: 48, height: 48)
                }
                Text(model.npub)
                    .lineLimit(1, reservesSpace: false)
                Spacer()
                Text("\(model.time) \(model.date)")
            }
            Text(model.content)
        }
    }
}

#Preview {
    ContentView()
}
