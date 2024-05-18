//
//  Created by Jericho Hasselbush on 5/15/24.
//

import Foundation
import Network

public protocol WebSocketDelegate {
    var stateHandler: ((_ state: NWConnection.State) -> Void)? { get set }
}

public protocol WebSocketClient: AnyObject {
    typealias ReceiveResult = Result<Data, Error>
    var delegate: WebSocketDelegate? { get set }

    func send(message: String, completion: @escaping (Swift.Error) -> Void)
    
    func receive(completion: @escaping (_ result: ReceiveResult) -> Void)
    func start() throws
    func disconnect()
}
