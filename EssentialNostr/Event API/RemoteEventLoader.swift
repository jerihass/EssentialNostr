//
//  Created by Jericho Hasselbush on 5/14/24.
//

import Foundation

final public class RemoteEventLoader {
    private let client: WebSocketClient
    public typealias Result = Swift.Result<Event, Error>
    public enum Error: Swift.Error, Equatable {
        case connectivity
        case invalidData
        case closed(sub: String, message: String)
        case eose(sub: String)
        case notice(message: String)
        case ok(sub: String, accepted: Bool, reason: String)
    }

    public init(client: WebSocketClient) {
        self.client = client
    }

    public func load(request: String, completion: @escaping (Result) -> Void) {
        client.receive(with: request) { result in
            switch result {
            case .success(let data):
                do {
                    let event = try RelayMessageMapper.map(data)
                    completion(.success(event))
                } catch {
                    if let error = error as? RemoteEventLoader.Error {
                        completion(.failure(error))
                    }
                }
            case .failure:
                completion(.failure(RemoteEventLoader.Error.connectivity))
            }
        }
    }
}

private class RelayMessageMapper {
    static func map(_ data: Data) throws -> Event {
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

        enum CodingKeys: CodingKey {
            case type
        }

        struct DecodingError: Swift.Error {}

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
