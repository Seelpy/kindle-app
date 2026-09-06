import SwiftUI

@main
struct DalsheLiveApp: App {
    @StateObject private var store = ReadingStore()
    @StateObject private var aiProxy = AIProxyStore()

    var body: some Scene {
        WindowGroup("Ещё пять") {
            ContentView()
                .environmentObject(store)
                .environmentObject(aiProxy)
                .frame(minWidth: 900, minHeight: 680)
                .task { await aiProxy.startIfNeeded() }
        }
        .windowStyle(.hiddenTitleBar)
    }
}
