import SwiftUI

@main
struct DalsheLiveApp: App {
    @StateObject private var store = ReadingStore()

    var body: some Scene {
        WindowGroup("Ещё пять") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 900, minHeight: 680)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
