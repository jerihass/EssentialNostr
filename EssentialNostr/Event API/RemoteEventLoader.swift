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
    public enum Error: Swift.Error {
        case connectivity
        case closed
        case invalidData
    }

    public init(client: WebSocketClient) {
        self.client = client
    }

    public func load(request: String, completion: @escaping (Error) -> Void) {
        client.receive(with: request) { result in
            switch result {
            case .success(let data):
                if let message = try? JSONDecoder().decode(RelayMessage.self, from: data) {
                    switch message.message {
                    case .event:
                        break
                    case .closed:
                        completion(.closed)
                    }
                } else {
                    completion(.invalidData)
                }
            case .failure:
                completion(.connectivity)
            }
        }
    }

    private struct RelayMessage: Decodable {
        let message: Message

        enum MessageType: String, Decodable {
            case event = "EVENT"
            case closed = "CLOSED"
        }

        enum Message {
            case event(String, RelayEvent)
            case closed(String, String)
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
                message = .event(sub, event)
            case .closed:
                let sub = try container.decode(String.self)
                let mess = try container.decode(String.self)
                message = .closed(sub, mess)
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

