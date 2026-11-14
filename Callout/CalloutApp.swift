import SwiftUI

@main
struct CalloutApp: App {
    @State private var model = TimerModel()

    var body: some Scene {
        WindowGroup {
            TimerView(model: model)
                .preferredColorScheme(.dark)
                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        }
    }
}
