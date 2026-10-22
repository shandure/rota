import Foundation

#if canImport(SwiftData)
import SwiftData

/// The one SwiftData container, shared between the app and the widget via the App Group.
public enum Store {
    public static let appGroupID = "group.com.yourname.rota"

    public static let schema = Schema([Pattern.self, Override.self])

    /// Creates the shared container. Call once per process and keep the result.
    public static func sharedContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            configuration = ModelConfiguration("Rota",
                                               schema: schema,
                                               groupContainer: .identifier(appGroupID))
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// A persistent store in the app's own container, not shared with the widget.
    /// Only used as a fallback when the App Group container cannot be opened.
    public static func localContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration("Rota", schema: schema)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
#endif
