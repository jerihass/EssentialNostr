//
//  Created by Jericho Hasselbush on 5/14/24.
//

import Foundation

public struct RelayMessage {

}

public protocol WebSocketClient {
    typealias ReceiveResult = Result<Data, Error>
    func receive(with request: String, completion: @escaping (ReceiveResult) -> Void)
}

final public class RemoteEventLoader {
    private let client: WebSocketClient
    public enum Error: Swift.Error {
        case connectivity
        case closed
    }

    public init(client: WebSocketClient) {
        self.client = client
    }

    public func load(request: String, completion: @escaping (Error) -> Void) {
        client.receive(with: request) { result in
            switch result {
            case .success:
                completion(.closed)

            case .failure(_):
                completion(.connectivity)
            }
        }
    }
}

