//
//  Created by Jericho Hasselbush on 6/2/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Nostr Events")
            .font(.title)
        List {
            noteView()
            noteView()
            noteView()
            noteView()
            noteView()
            noteView()
            noteView()
            noteView()
            noteView()
            noteView()
        }
        .listStyle(.plain)
    }

    private func noteView() -> some View {
        return Group {
            HStack {
                ZStack {
                    RoundedRectangle(cornerSize: .init(width: 8.0, height: 8.0), style: .continuous)
                        .frame(width: 48, height: 48)
                        .foregroundStyle(.ultraThinMaterial)
                    Image(systemName: "person.fill")
                        .frame(width: 48, height: 48)
                }
                Text("npubsadasdasdasdasdasdasd")
                    .lineLimit(1, reservesSpace: false)
                Spacer()
                Text("1303 5/31/24")
            }
            Text("Content content content Content content content Content content content Content content content Content content content Content content content Content content content Content content content ")
        }
    }
}

#Preview {
    ContentView()
}
