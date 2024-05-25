//
//  Created by Jericho Hasselbush on 5/15/24.
//

import Foundation
import Network

public enum WebSocketDelegateState {
    case ready
    case cancelled
}

public protocol WebSocketDelegate {
    var state: WebSocketDelegateState { get set }
    var stateHandler: ((_ state: WebSocketDelegateState) -> Void)? { get set }
}

public protocol WebSocketClient: AnyObject {
    typealias ReceiveResult = Result<Data, Error>
    var delegate: WebSocketDelegate? { get set }
    
    func start() throws
    func disconnect()

    func send(message: String, completion: @escaping (Swift.Error) -> Void)
    func receive(completion: @escaping (_ result: ReceiveResult) -> Void)
}
