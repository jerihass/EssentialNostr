//
//  Created by Jericho Hasselbush on 6/8/24.
//

import SwiftUI
import EssentialNostr

public struct EventView: View {
    let event: Event

    public init(event: Event) {
        self.event = event
    }

    public var body: some View {
        VStack {
            HStack {
                ZStack {
                    RoundedRectangle(cornerSize: .init(width: 8.0, height: 8.0), style: .continuous)
                        .frame(width: 48, height: 48)
                        .foregroundStyle(.ultraThinMaterial)
                    Image(systemName: "person.fill")
                        .frame(width: 48, height: 48)
                }
                Text(event.publicKey)
                    .lineLimit(1, reservesSpace: false)
                Spacer()
                VStack {
                    Text("\(eventDate)")
                    Text("\(eventTime)")
                }
            }
            Text(event.content)
        }
    }

    private var eventDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "en_US")

        return formatter.string(from: event.created)
    }

    private var eventTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_US")

        return formatter.string(from: event.created)
    }
}

#Preview {
    let event = Event(id: "eventID", publicKey: "pubkey", created: .now, kind: 1, tags: [], content: "some content", signature: "eventSignature")
    return EventView(event: event)
}
