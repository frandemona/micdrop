import Foundation
import Testing
@testable import MicDrop

@Suite struct TipLedgerTests {
    let defaults = UserDefaults(suiteName: "TipLedgerTests-\(UUID().uuidString)")!
    let locale = Locale(identifier: "en_US")

    @Test func startsAtZero() {
        #expect(TipLedger(defaults: defaults).formattedTotal(locale: locale) == "$0.00")
    }

    @Test func sumsExactlyAndPersists() {
        let ledger = TipLedger(defaults: defaults)
        ledger.record(Decimal(string: "1.99")!, currencyCode: "USD")
        ledger.record(Decimal(string: "4.99")!, currencyCode: "USD")
        #expect(ledger.formattedTotal(locale: locale) == "$6.98")
        #expect(TipLedger(defaults: defaults).totals["USD"] == Decimal(string: "6.98"))
    }

    @Test func keepsCurrenciesSeparate() {
        let ledger = TipLedger(defaults: defaults)
        ledger.record(Decimal(string: "1.99")!, currencyCode: "USD")
        ledger.record(Decimal(string: "2.29")!, currencyCode: "EUR")
        #expect(ledger.formattedTotal(locale: locale) == "€2.29 + $1.99")
    }
}
