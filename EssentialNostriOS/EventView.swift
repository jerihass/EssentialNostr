//
//  Created by Jericho Hasselbush on 6/8/24.
//

import SwiftUI
import EssentialNostr

public struct EventModel {
    let event: Event
    let id = UUID()
    
    var publicKey: String { event.publicKey }
    var content: String { event.content }
    var eventDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "en_US")

        return formatter.string(from: event.created)
    }

    var eventTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_US")

        return formatter.string(from: event.created)
    }
}

public struct EventView: View {
    let model: EventModel

    public init(model: EventModel) {
        self.model = model
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
                Text(model.publicKey)
                    .lineLimit(1, reservesSpace: false)
                Spacer()
                VStack {
                    Text("\(model.eventDate)")
                    Text("\(model.eventTime)")
                }
            }
            Text(model.content)
        }
    }
}

#Preview {
    let event = Event(id: "eventID", publicKey: "pubkey", created: .now, kind: 1, tags: [], content: "some content", signature: "eventSignature")
    let model = EventModel(event: event)
    return EventView(model: model)
}
