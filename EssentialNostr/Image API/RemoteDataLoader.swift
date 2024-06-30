//
//  Created by Jericho Hasselbush on 6/30/24.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL)
}

public class RemoteDataLoader {
    let client: HTTPClient

    public init(client: HTTPClient) {
        self.client = client
    }

    public func load(url: URL) {
        client.get(from: url)
    }
}
