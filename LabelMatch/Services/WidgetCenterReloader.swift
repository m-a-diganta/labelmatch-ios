import WidgetKit

/// Asks WidgetKit to refresh the widgets.
struct WidgetCenterReloader: WidgetReloading {
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
