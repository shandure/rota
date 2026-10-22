import SwiftUI
import SwiftData
import RotaCore

/// Home screen: one month of the active pattern (§4.1).
struct MonthView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: Pattern.listOrder) private var patterns: [Pattern]
    @Environment(CalendarSync.self) private var calendarSync

    @State private var visibleMonth = RotaEngine.startOfMonth(containing: Calendar.current.startOfDay(for: .now))
    @State private var slideFrom: Edge = .trailing
    @State private var selectedDay: DayShift?
    @State private var builder: PatternBuilderView.Mode?
    @State private var showingSettings = false

    private var calendar: Calendar { .current }
    private var today: Date { calendar.startOfDay(for: .now) }
    private var activePattern: Pattern? { patterns.first(where: \.isActive) ?? patterns.first }
    private var isCurrentMonth: Bool { calendar.isDate(visibleMonth, equalTo: today, toGranularity: .month) }

    var body: some View {
        NavigationStack {
            Group {
                if let pattern = activePattern {
                    monthContent(for: pattern)
                } else {
                    EmptyRotaView { builder = .create }
                }
            }
            .onAppear {
                guard let pattern = activePattern else { return }
                if DemoData.opensBuilder { builder = .edit(pattern) }
                if DemoData.opensDay { selectedDay = RotaEngine.entry(on: today, for: pattern, calendar: calendar) }
                if DemoData.opensSettings { showingSettings = true }
            }
            .navigationTitle(visibleMonth.formatted(.dateTime.month(.wide).year()))
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .sheet(item: $selectedDay) { day in
                if let pattern = activePattern {
                    DayDetailView(date: day.date, pattern: pattern)
                }
            }
            .sheet(item: $builder) { mode in
                PatternBuilderView(mode: mode)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    // MARK: Month content

    @ViewBuilder
    private func monthContent(for pattern: Pattern) -> some View {
        let grid = RotaEngine.monthGrid(containing: visibleMonth, calendar: calendar)
        let entries = RotaEngine.shifts(in: grid, for: pattern, calendar: calendar)
        let monthOnly = entries.filter { calendar.isDate($0.date, equalTo: visibleMonth, toGranularity: .month) }

        VStack(spacing: Spacing.s12) {
            MonthGrid(month: visibleMonth,
                      entries: entries,
                      today: today,
                      calendar: calendar) { selectedDay = $0 }
                .id(visibleMonth)
                .transition(.push(from: slideFrom))
            MonthSummary(summary: RotaEngine.summary(of: monthOnly))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.screen)
        .padding(.top, Spacing.s8)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    if value.translation.width < -50 {
                        move(by: 1)
                    } else if value.translation.width > 50 {
                        move(by: -1)
                    }
                }
        )
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showingSettings = true
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            if !isCurrentMonth {
                Button("Today") { goToToday() }
            }
            Button {
                move(by: -1)
            } label: {
                Label("Previous month", systemImage: "chevron.left")
            }
            Button {
                move(by: 1)
            } label: {
                Label("Next month", systemImage: "chevron.right")
            }
            Menu {
                ForEach(patterns) { pattern in
                    Button {
                        activate(pattern)
                    } label: {
                        if pattern.persistentModelID == activePattern?.persistentModelID {
                            Label(pattern.name, systemImage: "checkmark")
                        } else {
                            Text(pattern.name)
                        }
                    }
                }
                if !patterns.isEmpty { Divider() }
                Button("New pattern…") { builder = .create }
                if let active = activePattern {
                    Button("Edit pattern…") { builder = .edit(active) }
                }
            } label: {
                Label("Patterns", systemImage: "rectangle.stack")
            }
        }
    }

    // MARK: Actions

    private func move(by months: Int) {
        guard let target = calendar.date(byAdding: .month, value: months, to: visibleMonth) else { return }
        slideFrom = months > 0 ? .trailing : .leading
        withAnimation(.smooth) {
            visibleMonth = RotaEngine.startOfMonth(containing: target, calendar: calendar)
        }
        Analytics.track(.monthChanged(direction: months > 0 ? .forward : .back))
    }

    private func goToToday() {
        let target = RotaEngine.startOfMonth(containing: today, calendar: calendar)
        slideFrom = target > visibleMonth ? .trailing : .leading
        withAnimation(.smooth) { visibleMonth = target }
        Analytics.track(.monthChanged(direction: .today))
    }

    private func activate(_ pattern: Pattern) {
        for p in patterns { p.isActive = (p.persistentModelID == pattern.persistentModelID) }
        try? context.save()
        WidgetReloader.reload()
        calendarSync.dataChanged()
    }
}
