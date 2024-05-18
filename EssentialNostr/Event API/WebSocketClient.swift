//
//  Created by Jericho Hasselbush on 5/15/24.
//

import Foundation
import Network

public protocol WebSocketDelegate: AnyObject {
    var stateHandler: ((_ state: NWConnection.State) -> Void)? { get set }
}

public protocol WebSocketClient: AnyObject {
    typealias ReceiveResult = Result<Data, Error>
    var delegate: WebSocketDelegate? { get set }

    @available(*, deprecated, renamed: "delegate.stateHandler", message: "Use WebSocketDelegate instead")
    var stateHandler: ((_ state: NWConnection.State) -> Void)? { get set }

    @available(*, deprecated, renamed: "receive", message: "Use WebSocketClient.receive instead")
    var receiveHandler: ((_ result: ReceiveResult) -> Void)? { get set }

    func send(message: String, completion: @escaping (Swift.Error) -> Void)
    
    func receive(completion: @escaping (_ result: ReceiveResult) -> Void)
    func start() throws
    func disconnect()
}
