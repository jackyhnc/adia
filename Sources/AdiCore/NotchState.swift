import Foundation

/// Shared state for the notch panel. ObservableObject so both the controller
/// (via Combine) and SwiftUI views can react to expand/collapse changes.
@MainActor
public final class NotchState: ObservableObject {
    public static let shared = NotchState()

    @Published public private(set) var isExpanded: Bool = false

    private init() {}

    public func expand() { isExpanded = true }
    public func collapse() { isExpanded = false }
    public func toggle() { isExpanded.toggle() }
}
