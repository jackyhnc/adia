import Foundation

/// Shared state for the notch panel. ObservableObject so both the controller
/// (via Combine) and SwiftUI views can react to expand/collapse changes.
@MainActor
public final class NotchState: ObservableObject {
    public static let shared = NotchState()

    @Published public private(set) var isExpanded: Bool = false
    /// True while the session creation form is visible (idle state, form mode).
    @Published public private(set) var isCreating: Bool = false

    private init() {}

    public func expand() { isExpanded = true }
    public func collapse() {
        isExpanded = false
        isCreating = false
    }
    public func toggle() { isExpanded.toggle() }

    public func startCreating() {
        // Guard prevents double-firing CombineLatest when already expanded.
        if !isExpanded { isExpanded = true }
        isCreating = true
    }

    public func stopCreating() {
        isCreating = false
    }
}
