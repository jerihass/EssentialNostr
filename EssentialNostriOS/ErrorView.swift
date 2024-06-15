//
//  Created by Jericho Hasselbush on 6/9/24.
//

import SwiftUI

public struct ErrorViewModel {
    var message: String
    
    public init(message: String) {
        self.message = message
    }
}

public struct ErrorView: View {
    @State private var model: ErrorViewModel

    public init(model: ErrorViewModel) {
        self.model = model
    }

    public var body: some View {
        if !model.message.isEmpty {
            Text(model.message)
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .background(.red)
                .onTapGesture { withAnimation {
                    model.message = ""
                }}
        }
    }
}

#Preview {
    let model = ErrorViewModel(message: "Some Error")
    return ErrorView(model: model)
}
