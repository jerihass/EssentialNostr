//
//  Created by Jericho Hasselbush on 5/15/24.
//

import Foundation
import Network

public protocol WebSocketDelegate {
    func send(message: String, completion: Error)
    func receive(completion: @escaping (_ content: Data?, _ error: Error) -> Void)
}

public protocol WebSocketClient: AnyObject {
    typealias ReceiveResult = Result<Data, Error>
    var stateHandler: ((_ state: NWConnection.State) -> Void)? { get set }
    var receiveHandler: ((_ result: ReceiveResult) -> Void)? { get set }

    @available(*, deprecated, renamed: "WebSocketDelegate", message: "Use WebSocketDelegate.send and WebSocketDelegate.receive")
    func receive(with request: String, completion: @escaping (ReceiveResult) -> Void)
    func start() throws
    func disconnect()
}
