import SwiftUI
import SwiftData
import WidgetKit
import RotaCore

/// One timeline entry: a day plus everything the small and medium layouts need.
struct RotaEntry: TimelineEntry {
    let date: Date
    let patternName: String?
    let day: WidgetDay?
    let isUnlocked: Bool

    static func empty(at date: Date, unlocked: Bool) -> RotaEntry {
        RotaEntry(date: date, patternName: nil, day: nil, isUnlocked: unlocked)
    }
}

/// Reads the active pattern from the shared App Group store (§4.6).
struct RotaProvider: TimelineProvider {
    private let calendar = Calendar.current

    func placeholder(in context: Context) -> RotaEntry {
        entry(for: Self.sample, at: calendar.startOfDay(for: .now), unlocked: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (RotaEntry) -> Void) {
        let today = calendar.startOfDay(for: .now)
        if context.isPreview {
            completion(entry(for: Self.sample, at: today, unlocked: true))
            return
        }
        let pattern = Self.activePattern()
        completion(entry(for: pattern ?? Self.sample, at: today, unlocked: Entitlement.isUnlocked))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RotaEntry>) -> Void) {
        let today = calendar.startOfDay(for: .now)
        let unlocked = Entitlement.isUnlocked
        guard let pattern = Self.activePattern() else {
            completion(Timeline(entries: [.empty(at: today, unlocked: unlocked)], policy: .atEnd))
            return
        }
        // One entry per day for the next 7 days; WidgetKit asks again when they run out.
        let days = RotaEngine.widgetDays(from: today, for: pattern, calendar: calendar)
        let entries = days.map { day in
            RotaEntry(date: day.date, patternName: pattern.name, day: day, isUnlocked: unlocked)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    // MARK: Data

    private func entry(for pattern: PatternSnapshot, at date: Date, unlocked: Bool) -> RotaEntry {
        let day = RotaEngine.widgetDays(from: date, count: 1, for: pattern, calendar: calendar).first
        return RotaEntry(date: date, patternName: pattern.name, day: day, isUnlocked: unlocked)
    }

    /// The active pattern (or the first one) as a snapshot, read from the shared store.
    private static func activePattern() -> PatternSnapshot? {
        guard let container = try? Store.sharedContainer() else { return nil }
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<Pattern>(sortBy: Pattern.listOrder)
        descriptor.fetchLimit = 10
        guard let patterns = try? context.fetch(descriptor) else { return nil }
        return (patterns.first { $0.isActive } ?? patterns.first)?.snapshot
    }

    /// Gallery and preview data; never shown once the user has a pattern.
    private static var sample: PatternSnapshot {
        let today = Calendar.current.startOfDay(for: .now)
        let start = Calendar.current.date(byAdding: .day, value: -83, to: today) ?? today
        return PatternSnapshot(name: "Ward 7", startDate: start, cycle: Preset.twoDayTwoNightFourOff.cycle)
    }
}

struct RotaWidget: Widget {
    static let kind = "RotaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: RotaProvider()) { entry in
            RotaWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Rota")
        .description("Today's shift and the week ahead.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
