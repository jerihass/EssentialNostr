//
//  Created by Jericho Hasselbush on 5/14/24.
//

import Foundation

public protocol WebSocketClient {
    func receive(with request: String)
}

final public class RemoteEventLoader {
    private let client: WebSocketClient

    public init(client: WebSocketClient) {
        self.client = client
    }

    public func load(request: String) {
        client.receive(with: request)
    }
}

