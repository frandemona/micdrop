#if APPSTORE
import Observation
import StoreKit

@Observable
final class StoreKitTipJar {
    enum Status: Equatable {
        case idle, purchasing, thanks, failed
    }

    static let productIDs = [
        "ro.zereb.MicDrop.tip.small",
        "ro.zereb.MicDrop.tip.medium",
        "ro.zereb.MicDrop.tip.large",
    ]
    static let emoji = [
        "ro.zereb.MicDrop.tip.small": "😃",
        "ro.zereb.MicDrop.tip.medium": "😁",
        "ro.zereb.MicDrop.tip.large": "😍",
    ]

    let ledger: TipLedger
    private(set) var products: [Product] = []
    private(set) var status: Status = .idle
    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init(ledger: TipLedger = TipLedger()) {
        self.ledger = ledger
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
    }

    func loadProducts() async {
        guard products.isEmpty else { return }
        products = (try? await Product.products(for: Self.productIDs))?.sorted { $0.price < $1.price } ?? []
    }

    func purchase(_ product: Product) async {
        status = .purchasing
        do {
            switch try await product.purchase() {
            case .success(let verification):
                await handle(verification)
            case .userCancelled, .pending:
                status = .idle
            @unknown default:
                status = .idle
            }
        } catch {
            status = .failed
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else {
            status = .failed
            return
        }
        if let price = transaction.price, let currency = transaction.currency {
            ledger.record(price, currencyCode: currency.identifier)
        }
        await transaction.finish()
        status = .thanks
    }
}
#endif
