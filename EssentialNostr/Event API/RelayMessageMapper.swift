//
//  Created by Jericho Hasselbush on 5/15/24.
//

import Foundation

final class RelayMessageMapper {
    internal static func map(_ data: Data) throws -> Event {
        if let message = try? JSONDecoder().decode(RelayMessage.self, from: data) {
            switch message.message {
            case let .event(_, event):
                return event.local
            case let .closed(sub, message):
                throw RemoteEventLoader.Error.closed(sub: sub, message: message)
            case .eose(let sub):
                throw RemoteEventLoader.Error.eose(sub: sub)
            case let .notice(message: mess):
                throw RemoteEventLoader.Error.notice(message: mess)
            case let .ok(sub, accepted, reason):
                throw RemoteEventLoader.Error.ok(sub: sub, accepted: accepted, reason: reason)
            }
        } else {
            throw RemoteEventLoader.Error.invalidData
        }
    }

    private struct RelayMessage: Decodable {
        let message: Message

        enum MessageType: String, Decodable {
            case event = "EVENT"
            case closed = "CLOSED"
            case eose = "EOSE"
            case notice = "NOTICE"
            case ok = "OK"
        }

        enum Message {
            case event(sub: String, event: RelayEvent)
            case closed(sub: String, message: String)
            case eose(sub: String)
            case notice(message: String)
            case ok(sub: String, accepted: Bool, reason: String)
        }

        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            let type = try container.decode(MessageType.self)
            switch type {
            case .event:
                let sub = try container.decode(String.self)
                let event = try container.decode(RelayEvent.self)
                message = .event(sub: sub, event: event)
            case .closed:
                let sub = try container.decode(String.self)
                let mess = try container.decode(String.self)
                message = .closed(sub: sub, message: mess)
            case .eose:
                let sub = try container.decode(String.self)
                message = .eose(sub: sub)
            case .notice:
                let mess = try container.decode(String.self)
                message = .notice(message: mess)
            case .ok:
                let sub = try container.decode(String.self)
                let accepted = try container.decode(Bool.self)
                let mess = try container.decode(String.self)
                message = .ok(sub: sub, accepted: accepted, reason: mess)
            }
        }
    }

    private struct RelayEvent: Decodable {
        let id: String
        let pubkey: String
        let created_at: Double
        let kind: UInt16
        let tags: [[String]]
        let content: String
        let sig: String

        var local: Event {
            return Event(id: id, pubkey: pubkey, created_at: Date(timeIntervalSince1970: created_at), kind: kind, tags: tags, content: content, sig: sig)
        }
    }
}
