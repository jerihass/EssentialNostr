//
//  Created by Jericho Hasselbush on 6/15/24.
//

import XCTest
import EssentialNostr
@testable import EssentialNostriOS

class FeedViewModelIntegrationTests: XCTestCase {
    func test_feedViewTitle() {
        let sut = TitleViewModel()

        XCTAssertEqual(sut.title, localized("EVENT_VIEW_TITLE"))
    }

    func test_fetchEvents_loadsEventsIntoModel() {
        let events = events()
        var sut = FeedViewModel(eventSource: { events })

        sut.fetchEvents()

        XCTAssertEqual(sut.events, events)
    }

    private func events() -> [EventModel] {
        return [
            Event(id: "eventID1", publicKey: "pubkey1", created: .distantFuture, kind: 1, tags: [], content: "contents some 1", signature: "sig1"),
            Event(id: "eventID2", publicKey: "pubkey2", created: .now, kind: 1, tags: [], content: "contents some 2", signature: "sig2"),
            Event(id: "eventID3", publicKey: "pubkey3", created: .now - 314159268, kind: 1, tags: [], content: "contents some 3", signature: "sig3"),
            Event(id: "eventID4", publicKey: "pubkey4", created: .distantPast, kind: 1, tags: [], content: "contents some 4", signature: "sig4")
        ].map(EventModel.init)
    }
}

extension EventModel: Equatable {
    public static func == (lhs: EventModel, rhs: EventModel) -> Bool {
        lhs.id == rhs.id
    }
}
