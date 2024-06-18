//
//  Created by Jericho Hasselbush on 5/15/24.
//

import Foundation
import Network

public enum WebSocketDelegateState {
    case ready
    case cancelled
}

public protocol WebSocketClient: AnyObject {
    typealias ReceiveResult = Result<Data, Error>
    var stateHandler: ((_ state: WebSocketDelegateState) -> Void)? { get set }

    func start() throws
    func disconnect()

    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads if needed.
    func send(message: String, completion: @escaping (Swift.Error) -> Void)

    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads if needed.
    func receive(completion: @escaping (_ result: ReceiveResult) -> Void)
}
