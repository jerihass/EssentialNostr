//
//  Created by Jericho Hasselbush on 5/15/24.
//

import Foundation
import Network

public protocol WebSocketDelegate: AnyObject {
    func send(message: String, completion: @escaping (Error) -> Void)
    func receive(completion: @escaping (_ result: Result<Data, Error>) -> Void)
}

public protocol WebSocketClient: AnyObject {
    typealias ReceiveResult = Result<Data, Error>
    var delegate: WebSocketDelegate? { get set }
    @available(*, deprecated, renamed: "WebSocketDelegate.stateHandler", message: "Use WebSocketDelegate instead")
    var stateHandler: ((_ state: NWConnection.State) -> Void)? { get set }

    @available(*, deprecated, renamed: "WebSocketDelegate.receiveHandler", message: "Use WebSocketDelegate instead")
    var receiveHandler: ((_ result: ReceiveResult) -> Void)? { get set }

    @available(*, deprecated, renamed: "send", message: "Use send / receive instead")
    func receive(with request: String, completion: @escaping (ReceiveResult) -> Void)

    func send(message: String, completion: @escaping (Swift.Error) -> Void)
    func receive(completion: @escaping (_ result: ReceiveResult) -> Void)
    func start() throws
    func disconnect()
}
