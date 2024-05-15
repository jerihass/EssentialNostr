//
//  Created by Jericho Hasselbush on 5/14/24.
//

import Foundation

public protocol WebSocketClient {
    typealias ReceiveResult = Result<Data, Error>
    func receive(with request: String, completion: @escaping (ReceiveResult) -> Void)
}

final public class RemoteEventLoader {
    private let client: WebSocketClient
    public typealias Result = Swift.Result<[Event], Error>
    public enum Error: Swift.Error {
        case connectivity
        case closed
        case invalidData
    }

    public init(client: WebSocketClient) {
        self.client = client
    }

    public func load(request: String, completion: @escaping (Result) -> Void) {
        client.receive(with: request) { result in
            switch result {
            case .success(let data):
                if let message = try? JSONDecoder().decode(RelayMessage.self, from: data) {
                    switch message.message {
                    case .event:
                        break
                    case .closed:
                        completion(.failure(.closed))
                    case .eose:
                        completion(.success([]))
                    }
                } else {
                    completion(.failure(.invalidData))
                }
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }

    private struct RelayMessage: Decodable {
        let message: Message

        enum MessageType: String, Decodable {
            case event = "EVENT"
            case closed = "CLOSED"
            case eose = "EOSE"
        }

        enum Message {
            case event(sub: String, event: RelayEvent)
            case closed(sub: String, message: String)
            case eose(sub: String)
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
            }
        }
    }

    private struct RelayEvent: Decodable {
        let id: String
        let pubkey: String
        let created_at: Date
        let kind: UInt16
        let tags: [[String]]
        let content: String
        let sig: String
    }
}

