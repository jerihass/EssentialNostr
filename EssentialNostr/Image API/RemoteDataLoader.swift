//
//  Created by Jericho Hasselbush on 6/30/24.
//

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<(data: Data, response: HTTPURLResponse), Error>
    func get(from url: URL, completion: @escaping (Result) -> Void)
}

public class RemoteDataLoader {
    let client: HTTPClient
    public typealias Result = Swift.Result<Data, Error>
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public init(client: HTTPClient) {
        self.client = client
    }

    public func load(url: URL, completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .failure:
                completion(.failure(.connectivity))
            case let .success((data, response)):
                if response.statusCode == 200 {
                    completion(.success(data))
                } else {
                    completion(.failure(.invalidData))
                }
            }
        }
    }
}
