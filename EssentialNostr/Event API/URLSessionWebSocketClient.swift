//
//  Created by Jericho Hasselbush on 5/25/24.
//

import Foundation

public class URLSessionWebSocketClient: WebSocketClient {
    let url: URL
    let session: URLSession
    var task: URLSessionWebSocketTask?

    public enum Error: Swift.Error, Equatable {
        case stateHandlerNotSet
        case sendError
        case receiveError
    }

    public init(session: URLSession, url: URL) {
        self.session = session
        self.url = url
    }

    public func start() {
        self.task = session.webSocketTask(with: url)
        task?.resume()
    }

    public func disconnect() {
        task?.cancel()
        task = nil
    }

    public func send(message: String, completion: @escaping (Swift.Error) -> Void) {
        guard task != nil else {
            completion(Error.sendError)
            return
        }
        task?.send(.string(message)) {
            if let error = $0 {
                completion(error)
            }
        }
    }

    public func receive(completion: @escaping (_ result: Result<Data, Swift.Error>) -> Void) {
        guard task != nil else {
            completion(.failure(Error.receiveError))
            return
        }
        task?.receive { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(message):
                switch message {
                case let .data(data):
                    completion(.success(data))
                case let .string(string):
                    completion(.success(string.data(using: .utf8)!))
                @unknown default:
                    break
                }
            }
        }
    }
}
