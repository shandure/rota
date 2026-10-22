import SwiftUI
import SwiftData
import RotaCore
import OSLog

@main
struct RotaApp: App {
    private let container: ModelContainer
    @State private var purchases = PurchaseManager()

    init() {
        if DemoData.isRequested {
            let demo = try! Store.sharedContainer(inMemory: true)
            DemoData.seed(demo)
            container = demo
        } else {
            container = Self.makeContainer()
        }
    }

    var body: some Scene {
        WindowGroup {
            MonthView()
                .environment(purchases)
                .task { await purchases.load() }
        }
        .modelContainer(container)
    }

    /// The shared App Group store, falling back to a local store if the group container is
    /// unavailable (e.g. a build without the entitlement). Data is never silently discarded.
    private static func makeContainer() -> ModelContainer {
        do {
            return try Store.sharedContainer()
        } catch {
            Logger(subsystem: "com.yourname.rota", category: "store")
                .error("App Group store unavailable, using local store: \(error.localizedDescription)")
            return try! Store.localContainer()
        }
    }
}
