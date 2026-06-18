import Foundation
import Network

/// Observes network reachability via NWPathMonitor and publishes connectivity state.
/// Services check `isConnected` to skip futile API calls when offline; the UI reads
/// it to show an offline indicator in the notch.
@MainActor
public final class NetworkMonitor: ObservableObject {
    public static let shared = NetworkMonitor()

    @Published public private(set) var isConnected: Bool = true

    /// Consecutive classification-path failures since the last success. The circuit
    /// breaker trips after `circuitBreakerThreshold` failures and suppresses further
    /// API attempts until a success or a network-status transition resets it.
    @Published public private(set) var consecutiveFailures: Int = 0

    /// Number of consecutive failures before the circuit breaker trips.
    public static let circuitBreakerThreshold: Int = 3

    /// True when the circuit breaker has tripped: either the OS reports no connectivity
    /// or `consecutiveFailures` has hit the threshold.
    public var isCircuitOpen: Bool {
        !isConnected || consecutiveFailures >= Self.circuitBreakerThreshold
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.adia.networkmonitor", qos: .utility)

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let connected = path.status == .satisfied
                let wasConnected = self.isConnected
                self.isConnected = connected
                if connected && !wasConnected {
                    self.resetCircuitBreaker()
                    AppLogger.info("network.restored")
                } else if !connected && wasConnected {
                    AppLogger.warning("network.lost")
                }
            }
        }
        monitor.start(queue: queue)
    }

    /// Call after a successful API round-trip to reset the failure counter.
    public func recordSuccess() {
        consecutiveFailures = 0
    }

    /// Call after a failed API round-trip. Increments the counter and logs when
    /// the circuit breaker trips.
    public func recordFailure() {
        consecutiveFailures += 1
        if consecutiveFailures == Self.circuitBreakerThreshold {
            AppLogger.warning("network.circuit_breaker_tripped", [
                "consecutiveFailures": String(consecutiveFailures)
            ])
        }
    }

    /// Resets the circuit breaker (e.g. when connectivity is restored).
    public func resetCircuitBreaker() {
        consecutiveFailures = 0
    }

    // MARK: - Test helpers

    internal func _setConnectedForTesting(_ value: Bool) {
        isConnected = value
    }

    internal func _setConsecutiveFailuresForTesting(_ count: Int) {
        consecutiveFailures = count
    }
}
