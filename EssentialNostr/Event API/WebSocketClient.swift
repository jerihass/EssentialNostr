//
//  Created by Jericho Hasselbush on 5/15/24.
//

import Foundation
import Network

public protocol WebSocketClient: AnyObject {
    typealias ReceiveResult = Result<Data, Error>
    var stateHandler: ((_ state: NWConnection.State) -> Void)? { get set }
    var receiveHandler: ((_ result: ReceiveResult) -> Void)? { get set }

    func receive(with request: String, completion: @escaping (ReceiveResult) -> Void)
    func start() throws
    func disconnect()
}
