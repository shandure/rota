import SwiftUI
import SwiftData
import RotaCore
import OSLog

@main
struct RotaApp: App {
    private let container: ModelContainer
    @State private var purchases = PurchaseManager()
    @State private var calendarSync: CalendarSync

    init() {
        let container: ModelContainer
        if DemoData.isRequested {
            container = try! Store.sharedContainer(inMemory: true)
            DemoData.seed(container)
        } else {
            container = Self.makeContainer()
        }
        self.container = container
        _calendarSync = State(initialValue: CalendarSync(container: container))
        Analytics.start()
    }

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MonthView()
                .environment(purchases)
                .environment(calendarSync)
                .task {
                    if !PurchaseManager.isRunningTests { await purchases.load() }
                }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { trackAppOpened() }
        }
    }

    private func trackAppOpened() {
        let count = (try? container.mainContext.fetchCount(FetchDescriptor<Pattern>())) ?? 0
        Analytics.track(.appOpened(patternCount: count,
                                   hasPurchased: purchases.isUnlocked,
                                   calendarSyncOn: calendarSync.isEnabled))
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
