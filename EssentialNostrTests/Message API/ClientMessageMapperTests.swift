//
//  Created by Jericho Hasselbush on 5/18/24.
//

import XCTest

struct ClientMessage {
    enum Message {
        case close(sub: String)
    }
}

final class ClientMessageMapper {
    static func mapMessage(_ message: ClientMessage.Message) -> String {
        switch message {
        case .close(let sub):
            return "[\"CLOSE\",\"\(sub)\"]"
        }
    }
}

class ClientMessageMapperTests: XCTestCase {
    func test_map_closeMessageToString() {
        let subID = "sub_id"
        let closeMessage = ClientMessage.Message.close(sub: subID)
        let mapped = ClientMessageMapper.mapMessage(closeMessage)
        XCTAssertEqual(mapped, "[\"CLOSE\",\"\(subID)\"]")
    }
}

