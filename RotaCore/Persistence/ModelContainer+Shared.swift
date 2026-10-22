import Foundation

#if canImport(SwiftData)
import SwiftData

/// The one SwiftData container, shared between the app and the widget via the App Group.
public enum Store {
    public static let appGroupID = AppGroup.id

    public static let schema = Schema([Pattern.self, Override.self])

    public enum StoreError: Error {
        /// The process has no App Group entitlement, so the shared container cannot be used.
        case appGroupUnavailable
    }

    /// Creates the shared container. Call once per process and keep the result.
    /// Throws `StoreError.appGroupUnavailable` instead of letting SwiftData trap when the
    /// entitlement is missing (e.g. an unsigned build).
    public static func sharedContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            configuration = ModelConfiguration("Rota", schema: schema, url: try sharedStoreURL())
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// `<App Group>/Library/Application Support/Rota.store`, creating the directory if needed.
    /// SwiftData does not create intermediate directories inside a group container itself.
    public static func sharedStoreURL() throws -> URL {
        guard let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            throw StoreError.appGroupUnavailable
        }
        let directory = group.appendingPathComponent("Library/Application Support", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("Rota.store")
    }

    /// A persistent store in the app's own container, not shared with the widget.
    /// Only used as a fallback when the App Group container cannot be opened.
    public static func localContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration("Rota", schema: schema)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
#endif
