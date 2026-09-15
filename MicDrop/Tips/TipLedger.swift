import Foundation
import Observation

/// Running total of tips, kept per currency so amounts are never mixed.
@Observable
final class TipLedger {
    private static let key = "totalTipped"
    @ObservationIgnored private let defaults: UserDefaults
    private(set) var totals: [String: Decimal]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.dictionary(forKey: Self.key) as? [String: String] ?? [:]
        totals = stored.compactMapValues { Decimal(string: $0) }
    }

    func record(_ amount: Decimal, currencyCode: String) {
        totals[currencyCode, default: 0] += amount
        defaults.set(totals.mapValues { "\($0)" }, forKey: Self.key)
    }

    func formattedTotal(locale: Locale = .current) -> String {
        guard !totals.isEmpty else {
            return Decimal(0).formatted(.currency(code: locale.currency?.identifier ?? "USD").locale(locale))
        }
        return totals.keys.sorted()
            .map { totals[$0]!.formatted(.currency(code: $0).locale(locale)) }
            .joined(separator: " + ")
    }
}
