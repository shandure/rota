import Foundation
import WidgetKit

/// Any data change reloads the widget timelines (§4.6).
enum WidgetReloader {
    static func reload() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
