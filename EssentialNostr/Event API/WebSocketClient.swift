//
//  Created by Jericho Hasselbush on 5/15/24.
//

import Foundation
import Network

public enum WebSocketState {
    case ready
    case cancelled
}

public protocol WebSocketClient: AnyObject {
    typealias ReceiveResult = Result<Data, Error>
    var stateHandler: ((_ state: WebSocketState) -> Void)? { get set }

    func start() throws
    func disconnect()

    func send(message: String, completion: @escaping (Swift.Error) -> Void)
    func receive(completion: @escaping (_ result: ReceiveResult) -> Void)
}
