//
//  Created by Jericho Hasselbush on 6/9/24.
//

import SwiftUI

@Observable
public class ErrorViewModel {
    public var message: () -> String

    public init(message: @escaping () -> String) {
        self.message = message
    }

    public static var connectivityError: String = String(localized: "CONNECTIVITY_ERROR", table: "EventsFeed", bundle: Bundle(for: NostrLocalizedStrings.self))
}

public struct ErrorView: View {
    @State private var model: ErrorViewModel

    public init(model: ErrorViewModel) {
        self.model = model
    }

    public var body: some View {
        if !model.message().isEmpty {
            Text(model.message())
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .background(.red)
                .onTapGesture { withAnimation {
                    model.message = {""}
                }}
        }
    }
}

#Preview {
    let model = ErrorViewModel(message: {"Some Error"})
    return ErrorView(model: model)
}
