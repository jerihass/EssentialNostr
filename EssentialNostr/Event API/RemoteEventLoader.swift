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
        case unknown
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
                completion(RelayMessageMapper.mapData(data))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}
