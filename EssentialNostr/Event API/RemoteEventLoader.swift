//
//  Created by Jericho Hasselbush on 5/14/24.
//

import Foundation

public protocol WebSocketClient {
    func receive(with request: String, completion: @escaping (Error) -> Void)
}

final public class RemoteEventLoader {
    private let client: WebSocketClient
    public enum Error: Swift.Error {
        case connectivity
    }

    public init(client: WebSocketClient) {
        self.client = client
    }

    public func load(request: String, completion: @escaping (Error) -> Void = { _ in }) {
        client.receive(with: request) { error in
            completion(.connectivity)
        }
    }
}

