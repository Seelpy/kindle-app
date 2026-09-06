import SwiftUI

@main
struct DalsheLiveApp: App {
    @StateObject private var store = ReadingStore()

    var body: some Scene {
        WindowGroup("Дальше") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1080, minHeight: 760)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
