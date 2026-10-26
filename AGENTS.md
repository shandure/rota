# AGENTS.md — Rota (shift calendar for iOS)

This file is read automatically at the start of every Codex session. It contains everything you need: why the app exists, how to work on it, and the complete product spec. Treat the spec in Part B as the source of truth. If something is ambiguous, ask once; if it's not in the spec, it's out of scope.

---

# Part A — Context and working rules

## What we're building and why

Rota is a small, local-only iOS app for people who work a repeating shift pattern (nurses, police, warehouse, rail, care workers). They enter their pattern once — e.g. 2 days, 2 nights, 4 off — and the app shows every shift forever: month view, widget, and optionally their system calendar.

This is a solo indie project. It is being built by one person using Codex, with no backend, no accounts, and no team. The goal is a finished, trustworthy app on the App Store within a few weeks, not a platform.

## Who it's for

- Someone checking their rota in a car park at 6am on a phone with a cracked screen. Legibility and speed beat everything.
- They already type their rota into a calendar by hand, or use an ad-filled Android-port app. The bar is "better than paper".
- UK first: Monday week start by locale, 24-hour times, GBP pricing, UK DST (last Sunday of March and October).

## Business model

- Free: one pattern, month view, overrides.
- One-time purchase (£4.99, StoreKit 2 non-consumable): multiple patterns, calendar export, home-screen widget.
- No subscriptions, no ads, no trials, no dark patterns on the paywall. The paywall must always be dismissible.
- Expected numbers for an app like this: 5–20k downloads over the first year, 2–5% conversion. Revenue is not the point of v1; a finished, well-reviewed app is.

## What success looks like

Primary: a user creates a pattern, and 30 days later still opens the app and has set at least one override. Overrides mean it has become their real rota.

Secondary: 4.7+ star rating, ranking on App Store search for "shift calendar" and "4 on 4 off", and screenshots people share in a group chat.

## Where users come from (affects what we build)

- ~65% from App Store search → the month view and pattern builder must screenshot well; the first two store screenshots are those screens.
- Word of mouth on wards and in break rooms → the month view should look good enough that someone asks "what app is that?".
- A few Reddit/Facebook/TikTok posts → the pattern-builder preview is the demo moment.
- No paid ads, ever. Don't build anything that only makes sense with ads.

## Non-negotiables

1. **Correctness of dates.** A rota app that is wrong by one day is worse than no app. Every date calculation goes through `RotaEngine`, uses `Calendar.current` and `startOfDay`, and has a unit test. DST and time-zone fixtures are mandatory, not optional.
2. **Local only.** No network calls except StoreKit and PostHog. Nothing identifying leaves the device. Pattern names, notes, and shift times are never sent to analytics.
3. **Scope discipline.** Build the spec, in the order given, and nothing else. Do not add features, settings, or "nice to haves" without being asked. Section 9 of the spec lists what's explicitly out.
4. **Design discipline.** Use only the spacing scale, corner radii, colours and type styles in §6 of the spec. No ad-hoc values. If a screen needs something the design brief doesn't cover, use the nearest system default and flag it.
5. **Accessibility.** Every interactive element has a VoiceOver label. Dynamic Type must not break the month grid (cap the grid's font at `.xxLarge` with `.dynamicTypeSize(...)`, don't let it overflow).

## How to work in this repo

- **Stack:** Swift 5.10+, SwiftUI, SwiftData, WidgetKit, StoreKit 2, EventKit, PostHog iOS. iOS 17 minimum. Xcode project (not SPM-only). No third-party UI libraries.
- **Targets:** `Rota` (app), `RotaWidget` (widget extension), `RotaCore` (framework shared by both: models, `RotaEngine`, `Store`), `RotaTests`.
- **App Group:** `group.com.yourname.rota` — all SwiftData access goes through the shared container in `RotaCore`.
- **Structure:**
  ```
  Rota/
    App/            RotaApp.swift, AppDelegate if needed
    Features/
      Month/        MonthView, DayCell, MonthSummary
      Pattern/      PatternBuilderView, CycleEditor, PresetChips, PreviewStrip
      Day/          DayDetailView
      Settings/     SettingsView, CalendarSyncSection
      Paywall/      PaywallView, PurchaseManager
    Design/         Spacing.swift, Radius.swift, Palette.swift, Typography.swift
    Analytics/      Analytics.swift (one enum of events, one `track` function)
  RotaCore/
    Models/         Pattern, ShiftType, Override
    Engine/         RotaEngine
    Persistence/    ModelContainer+Shared
    Calendar/       CalendarExporter
  RotaWidget/
  RotaTests/
    EngineTests/    one file per concern: Cycle, Overrides, DST, TimeZone, Boundaries
  ```
- **Design tokens live in code.** `Spacing.s4 … .s32`, `Radius.cell = 8`, `Palette.day`, `Typography.dateNumber`, etc. Views reference tokens, never literals.
- **Build order:** follow §7 of the spec exactly. Finish and verify one step before starting the next. At the end of each step, run the tests and build both targets.
- **Tests:** `RotaEngine` has 100% test coverage before any UI is written. Use fixed dates in fixtures (e.g. `2026-03-28` for the March DST weekend), never `Date()`.
- **Commits:** one commit per completed build step, message in the form `Step 3: pattern builder with presets and preview`. Don't commit a broken build.
- **When something in the spec can't be done as written** (an API doesn't exist, a layout can't fit on iPhone SE), stop and say so with the two best alternatives. Don't silently substitute.
- **When finishing a step,** report: what was built, what was tested, anything deviating from the spec, and what to check in the simulator.

## Simulator checks the human will do after each step

- Step 2: scroll three months back and forward, check the summary counts by hand.
- Step 3: build a 2D 2N 4-off pattern starting on a known past date and compare the preview to a hand-written rota.
- Step 4: set a holiday, kill the app, relaunch, confirm it persists and the dot shows.
- Step 7: add the widget, change a shift in the app, confirm the widget updates.
- Step 8: turn on calendar sync, open Calendar.app, confirm events; turn it off, confirm they're gone and no other calendar was touched.

## Release checklist (step 10)

- App icon at 1024×1024, no alpha.
- Six screenshots per size class: month view, pattern builder with preview, day detail, widget on home screen, calendar sync, paywall. Light mode, iPhone 15 Pro Max and iPhone SE.
- App Store title: "Rota: Shift Calendar". Subtitle: "Your shift pattern, forever". Keywords field: shift,rota,calendar,4 on 4 off,nurse,police,nights,pattern,roster,work.
- Privacy nutrition label: "Data not collected" except analytics → "Usage Data, not linked to you".
- StoreKit product created in App Store Connect and tested in sandbox before submission.
- TestFlight to 5–10 real shift workers for a week before public release.

---

# Part B — Product spec


### 1. One-paragraph brief

Rota is a tiny, local-only iOS app for people who work a repeating shift pattern. The user builds their pattern once (e.g. 2 days, 2 nights, 4 off), picks the date it started, and the app shows every future shift forever — in a month view, in a widget, and optionally in their system calendar. No accounts, no sync, no team features. Free with one pattern; a one-time purchase unlocks multiple patterns, calendar export, and the widget. The app should feel like a good paper rota: glanceable, boring, trustworthy. If a feature isn't in this file, don't build it.

### 2. Stack & constraints

- Swift 5.10+, SwiftUI, iOS 17 minimum.
- Persistence: SwiftData, one container, shared with the widget via an App Group.
- Widget: WidgetKit, small and medium, read-only (no interaction needed).
- Purchases: StoreKit 2, one non-consumable `com.yourname.rota.unlock`.
- Calendar export: EventKit, writes to a dedicated calendar named after the pattern.
- Analytics: PostHog iOS SDK. Events in §8.
- No third-party UI libraries. No backend. No login.
- iPhone only, portrait only, light and dark mode both required.

### 3. Data model

```swift
@Model final class Pattern {
    var id: UUID
    var name: String                 // max 30 chars, e.g. "Ward 7"
    var startDate: Date              // start of day; the day cycle index 0 falls on
    var cycle: [ShiftType]           // ordered; repeats forever. Max length 56.
    var createdAt: Date
    var isActive: Bool               // only one pattern is active at a time; it drives the widget
    @Relationship(deleteRule: .cascade) var overrides: [Override]
}

enum ShiftKind: String, Codable, CaseIterable {
    case day, night, late, early, off, custom
}

struct ShiftType: Codable, Hashable {
    var kind: ShiftKind
    var label: String                // "Day", "Night", "Off", or user text for .custom (max 6 chars, shown in the cell)
    var colorHex: String
    var startTime: DateComponents?   // hour+minute, nil for .off
    var endTime: DateComponents?     // nil for .off; may be earlier than start (crosses midnight)
}

@Model final class Override {
    var id: UUID
    var date: Date                   // start of day
    var shift: ShiftType             // replaces the cycle's shift on this date (e.g. holiday, swap)
    var note: String?                // max 60 chars
    var pattern: Pattern?
}
```

Rules:
- Shift on date D = `overrides[D]` if present, else `cycle[(daysBetween(startDate, D) mod cycle.count)]`. Days before `startDate` use the same formula with negative modulo handled correctly so the pattern extends backwards too.
- "Day" means calendar day in the user's current time zone. Store `startOfDay`.
- A night shift belongs to the day it starts on. Don't try to be clever about this; it's how every rota is written.
- Built-in presets (§4.2) are just prefilled `cycle` arrays, not a separate type.

### 4. Screens

Exactly four screens plus the widget. Build in this order.

#### 4.1 Month (home)

- Navigation title: month and year, e.g. "October 2026". Swipe horizontally to change month; also "<" / ">" buttons in the toolbar for people who don't discover swipe. A "Today" button appears in the toolbar whenever the visible month isn't the current one.
- Standard 7-column grid, weeks start on `Calendar.current.firstWeekday`. Weekday initials across the top in caption font, secondary colour.
- Each day cell: the date number top-left in `.caption`, and the shift as a filled rounded rectangle (8pt radius) in the shift colour with the label centred in white (`.caption2.weight(.semibold)`). Off days: no fill, label hidden, date number in secondary colour. Days from adjacent months: shown, 30% opacity.
- Today: 2pt ring in `.primary` around the cell.
- Overridden days: a small dot in the top-right of the cell in the shift colour so users can see which days have been edited.
- Below the grid, a summary strip for the visible month: "14 shifts · 8 nights · 16 off" in `.footnote`, secondary colour. Count only `kind != .off`.
- Tapping a day opens Day Detail (§4.3) as a sheet.
- Toolbar right: a pattern menu (SF Symbol `rectangle.stack`) listing the user's patterns with a tick on the active one, plus "New pattern…" and "Edit pattern…". Toolbar left: settings gear → Settings (§4.4).
- Empty state (no patterns): centred SF Symbol `calendar.badge.clock`, headline "Set up your rota", body "Enter your pattern once. See every shift forever.", primary button "Create pattern" → Pattern Builder.

#### 4.2 Pattern Builder (sheet, also used for edit)

- `.presentationDetents([.large])`.
- Step layout in a `Form`, top to bottom:
  1. **Name** — text field, placeholder "Ward 7", autofocus on create.
  2. **Start from a preset** — horizontal scrolling chips: "4 on 4 off", "2D 2N 4 off", "Mon–Fri", "Continental (2-2-3)", "3 on 3 off", "5 on 2 off / 5 on 3 off", "Custom". Tapping a preset fills the cycle below; the user can still edit it. Default selection: none (empty cycle) on create; current cycle on edit.
  3. **Cycle** — the heart of the screen. A horizontal, reorderable row of cells, each showing the shift label in its colour. Below it, a row of shift-type buttons: Day, Night, Late, Early, Off, plus "+" for a custom type. Tapping a button appends that shift to the cycle. Each cell has an "x" on long press to remove, and the whole row supports drag to reorder. Show "Cycle: 8 days" beneath it. Cap at 56 cells.
  4. **Shift times** — a disclosure group, collapsed by default, listing each distinct shift type in the cycle with start and end `DatePicker`s (`.hourAndMinute`). Defaults: Day 07:00–19:00, Night 19:00–07:00, Late 13:00–21:00, Early 06:00–14:00. Only used for calendar export and the widget's "starts in" line; the app never needs them otherwise.
  5. **Start date** — `DatePicker` in `.date` style, with a one-line explanation beneath: "Pick any date you know the pattern's first day fell on." Default: today.
  6. **Preview** — the next 14 days rendered as a compact strip of coloured cells with weekday initials, live-updating as the user edits. This is what stops people getting the start date wrong.
- Toolbar: "Cancel" left, "Save" right (disabled until name non-empty and cycle has ≥ 1 cell). Edit mode adds a red "Delete pattern" button at the bottom with a confirmation dialog.
- Saving a second pattern without the unlock → present Paywall; keep form state for after purchase.
- Saving an edited pattern keeps existing overrides.

#### 4.3 Day Detail (sheet)

- `.presentationDetents([.medium])`.
- Header: full date ("Thursday 23 October"), then the shift as a large coloured pill with label and times, e.g. "Night · 19:00–07:00". Off days: "Off" in secondary colour.
- A segmented or chip row to override the shift for this day: all shift types in the pattern plus "Off" plus "Holiday" (a built-in `.custom` with label "HOL", colour `#9775FA`) plus "Sick" (label "SICK", colour `#868E96`). Selecting one creates/updates an Override. Selecting the shift the cycle already gives for that day deletes the Override.
- A note text field, placeholder "Swapped with Sam", 60 chars.
- Footer: "Reset to pattern" text button, visible only when an Override exists.
- Dismiss with swipe or "Done". Changes save immediately; no explicit save button.

#### 4.4 Settings

- Plain `List` with sections:
  - **Patterns** — the same list as the toolbar menu, with reorder and swipe-to-delete.
  - **Calendar** — toggle "Add shifts to Calendar" (gated by unlock). When turned on: request EventKit write permission, create (or find) a calendar named after the active pattern, and write the next 12 months of non-off shifts as timed events, plus all-day events for Holiday/Sick overrides. When any pattern or override changes, remove that pattern's events from today onwards and rewrite. When turned off, delete the calendar. Show a footnote: "Shifts appear in the Calendar app and anywhere else it syncs to."
  - **Widget** — one row, "Add the widget" → opens a short in-app explainer with the three steps to add a widget on iOS, with a screenshot. Gated by unlock.
  - **Unlock** — if not purchased: a row "Unlock everything — £4.99" → Paywall. If purchased: "Unlocked, thank you." with a `checkmark.seal`.
  - **About** — version, "Rate on the App Store", "Send feedback" (mailto), privacy line "All your data stays on this phone."

#### 4.5 Paywall

- Full-screen cover, "X" top-left, never trap the user.
- Headline: "Unlock everything"
- Benefit rows with SF Symbols: "Multiple patterns", "Shifts in your Calendar app", "Home screen widget", "One payment, yours forever".
- Primary button with live price: "Unlock for £4.99". Under it, "Restore purchases".
- Nothing else. No countdowns, no fake crossed-out prices.
- On success: dismiss, success haptic, resume where the user was.

#### 4.6 Widget

- Read-only, driven by the active pattern.
- Small: today's shift as a large coloured pill with label, the date above in caption, and beneath it "Next: Day · Fri" for the next non-off shift.
- Medium: a 7-day strip starting today — weekday initial, date number, coloured cell with label — plus the pattern name top-left.
- Not purchased: same layout blurred with "Unlock in app" centred.
- Timeline: one entry per day for the next 7 days, refresh policy `.atEnd`. Reload on any data change via `WidgetCenter.shared.reloadAllTimelines()`.

### 5. Calendar export rules (EventKit)

- Event title = pattern name + " · " + shift label, e.g. "Ward 7 · Night".
- Timed events use the shift's start/end; a night that crosses midnight ends the next day.
- Off days produce no event.
- Holiday/Sick overrides produce all-day events titled "Holiday" / "Sick".
- Events carry a URL `rota://pattern/<id>/<yyyy-mm-dd>` so the app can find and delete its own events reliably. Never delete events the app didn't create.
- Write in batches; `EKEventStore.commit()` once at the end.

### 6. Design brief

Calm and utilitarian. This is a tool people glance at in a car park at 6am. Legibility beats charm.

- Typography: system font. `.largeTitle` for the month title, `.caption` for date numbers, `.caption2.weight(.semibold)` for shift labels in cells, `.title2.weight(.semibold)` for the Day Detail pill. No rounded design — keep it neutral.
- Spacing scale: 4, 8, 12, 16, 24, 32. Month grid cell gap 4pt. Screen horizontal padding 16pt.
- Corner radius: 8pt for shift cells and pills, 12pt for cards.
- Colours: system semantic colours for text and backgrounds. Shift palette (hex): Day `#FFA94D`, Night `#4C6EF5`, Late `#F783AC`, Early `#38D9A9`, Off = no fill, Holiday `#9775FA`, Sick `#868E96`. Custom types pick from: `#FF6B6B`, `#FFD43B`, `#69DB7C`, `#4DABF7`. White label text on all fills; verify contrast on `#FFD43B` and `#38D9A9` and switch those two to `.black` text if they fail.
- Motion: `.smooth` for month changes, nothing else animates. No animation on first load.
- Haptics: light impact when an override is set. Success on purchase. That's all.
- Copy: short, plain, no exclamation marks, no jargon. Say "Off", not "Rest day".
- Icon: a 3×3 grid of rounded squares, five filled in the Day and Night colours, four empty, on a near-black background. Provide 1024×1024.

### 7. Build order

1. Models + a `RotaEngine` with `shift(on: Date, for: Pattern)`, `shifts(in: DateInterval)`, `nextShift(after:)`, and the override merge. Unit-test with fixtures: cycle lengths 1, 2, 8, 56; dates before `startDate`; overrides; a DST change weekend; a time-zone change.
2. Month screen with real data, month navigation, summary strip.
3. Pattern Builder with presets, reorderable cycle, live preview. Get the preview right before anything else — it's the trust moment.
4. Day Detail and overrides.
5. Settings skeleton, About.
6. StoreKit 2, Paywall, second-pattern gate. Test with a StoreKit configuration file.
7. Widget with App Group.
8. Calendar export.
9. PostHog events.
10. Icon, screenshots, TestFlight.

Ship after step 10. Everything else is v2.

### 8. Analytics events (PostHog)

No PII. Pattern names, notes and shift times are never sent.

| Event | Properties |
|---|---|
| `app_opened` | `pattern_count`, `has_purchased`, `calendar_sync_on` |
| `pattern_created` | `cycle_length`, `preset` (name or `custom`), `distinct_shift_kinds` |
| `pattern_edited` | `cycle_length` |
| `pattern_deleted` | `age_days` |
| `override_set` | `kind` (`day`/`night`/…/`holiday`/`sick`/`off`), `has_note` |
| `month_changed` | `direction` (`forward`/`back`/`today`) |
| `paywall_shown` | `trigger` (`second_pattern`/`calendar`/`widget`/`settings`) |
| `purchase_completed` | `price` |
| `purchase_restored` | — |
| `calendar_sync_toggled` | `on` (bool), `permission_granted` (bool) |

First question to answer: what fraction of users who create a pattern open the app again 7 and 30 days later, and how many of them set at least one override? Overrides are the signal that the app has become their real rota.

### 9. Explicitly out of scope for v1

Accounts, iCloud sync, sharing a rota with colleagues, team or ward views, pay or hours calculators, overtime tracking, Apple Watch, iPad, lock-screen widgets, notifications/reminders before shifts, importing rotas from PDFs or spreadsheets, non-repeating patterns (every day entered by hand), week view, themes, Siri.

### 10. Definition of done

- Create a 2D 2N 4-off pattern with a start date three months ago; every day in the month view matches a hand-written rota for that pattern.
- Days before the start date are correct.
- Set a Holiday override, kill and relaunch: it persists, the month dot shows, the summary strip excludes it.
- Edit the pattern's cycle: overrides survive; the preview and month view update instantly.
- DST weekend (last Sunday in March / October, UK): no shift shifts to the wrong day.
- Change device time zone: no shift moves day.
- Widget matches the month view for the next 7 days.
- Calendar export: turn on, check Calendar app, set an override, see the event change, turn off, events gone, no other calendars touched.
- Paywall appears on second pattern, purchase and restore work in the StoreKit test environment.
- VoiceOver reads a day cell as "Thursday 23 October, Night shift, 19:00 to 07:00, button".
- No layout breaks on iPhone SE (3rd gen) or 15 Pro Max, light and dark.
