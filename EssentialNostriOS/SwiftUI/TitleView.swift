//
//  Created by Jericho Hasselbush on 6/15/24.
//

import SwiftUI

public struct TitleViewModel {
    let title: String = String(localized: "EVENT_VIEW_TITLE", table: "EventsFeed", bundle: Bundle(for: NostrLocalizedStrings.self))
}

public struct TitleView: View {
    private let model: TitleViewModel = .init()

    public init() {}

    public var body: some View {
        Text(model.title)
            .font(.title)
    }
}

#Preview {
    TitleView()
}
