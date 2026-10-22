import Foundation
import SwiftData
import RotaCore

/// Seed data for the `--demo` launch argument (CI screenshots, App Store screenshots).
/// Never used in a normal launch.
enum DemoData {
    static let launchArgument = "--demo"
    /// With `--demo`, opens the pattern builder on the demo pattern at launch (screenshots).
    static let builderArgument = "--demo-builder"

    /// With `--demo`, opens Day Detail for today at launch (screenshots).
    static let dayArgument = "--demo-day"

    /// With `--demo`, opens Settings at launch (screenshots).
    static let settingsArgument = "--demo-settings"

    static var isRequested: Bool { CommandLine.arguments.contains(launchArgument) }
    static var opensBuilder: Bool { isRequested && CommandLine.arguments.contains(builderArgument) }
    static var opensDay: Bool { isRequested && CommandLine.arguments.contains(dayArgument) }
    /// With `--demo`, opens Settings and then the paywall (screenshots).
    static let paywallArgument = "--demo-paywall"

    static var opensSettings: Bool {
        isRequested && (CommandLine.arguments.contains(settingsArgument) || opensPaywall)
    }
    static var opensPaywall: Bool { isRequested && CommandLine.arguments.contains(paywallArgument) }

    @MainActor
    static func seed(_ container: ModelContainer) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        // Start 83 days ago so today is a night in the 2D 2N 4-off reference pattern.
        let start = calendar.date(byAdding: .day, value: -83, to: today) ?? today
        let pattern = Pattern(name: "Ward 7",
                              startDate: start,
                              cycle: [.day, .day, .night, .night, .off, .off, .off, .off],
                              createdAt: today,
                              isActive: true)
        let context = container.mainContext
        context.insert(pattern)
        let second = Pattern(name: "Bank shifts",
                             startDate: start,
                             cycle: Preset.fourOnFourOff.cycle,
                             createdAt: today,
                             isActive: false,
                             sortOrder: 1)
        context.insert(second)

        func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: today) ?? today }
        let holiday = Override(date: day(5), shift: .holiday, note: "Cornwall", pattern: pattern)
        let swap = Override(date: day(-3), shift: .late, note: "Swapped with Sam", pattern: pattern)
        let sick = Override(date: day(-10), shift: .sick, pattern: pattern)
        for override in [holiday, swap, sick] { context.insert(override) }
        try? context.save()
    }
}
