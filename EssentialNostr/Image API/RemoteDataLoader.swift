//
//  Created by Jericho Hasselbush on 6/30/24.
//

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<HTTPURLResponse, Error>
    func get(from url: URL, completion: @escaping (Result) -> Void)
}

public class RemoteDataLoader {
    let client: HTTPClient
//    public typealias Result = Swift.Result<HTTPURLResponse, Error>

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public init(client: HTTPClient) {
        self.client = client
    }

    public func load(url: URL, completion: @escaping (Error) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .failure:
                completion(.connectivity)
            case .success:
                completion(.invalidData)
            }
        }
    }
}
