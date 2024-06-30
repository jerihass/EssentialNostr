//
//  Created by Jericho Hasselbush on 6/30/24.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (Error) -> Void)
}

public class RemoteDataLoader {
    let client: HTTPClient
    public enum Error: Swift.Error {
        case connectivity
    }

    public init(client: HTTPClient) {
        self.client = client
    }

    public func load(url: URL, completion: @escaping (Swift.Error) -> Void) {
        client.get(from: url) { error in
            completion(Error.connectivity)
        }
    }
}
