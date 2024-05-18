//
//  Created by Jericho Hasselbush on 5/14/24.
//

import Foundation

final public class RemoteEventLoader: EventLoader {
    public func request(_ message: String) {
        client.send(message: message, completion: { _ in })
    }
    
    public func load(_ completion: @escaping (LoadEventResult) -> Void) {
        client.receive { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .success(let data):
                completion(RelayMessageMapper.mapData(data))
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
    
@available(*, deprecated, renamed: "request", message: "Event Loader request is now two functions: request and load.")
    public func load(request: String, completion: @escaping (LoadEventResult) -> Void) {
        self.request(request)
        self.load(completion)
    }

    private let client: WebSocketClient
    public typealias Result = LoadEventResult

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
}
