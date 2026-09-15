#if APPSTORE
import StoreKit
import SwiftUI

struct StoreTipsView: View {
    let tipJar: StoreKitTipJar

    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 6) {
                if tipJar.products.isEmpty {
                    ProgressView().controlSize(.small)
                } else {
                    ForEach(tipJar.products, id: \.id) { product in
                        Button {
                            Task { await tipJar.purchase(product) }
                        } label: {
                            let emoji = StoreKitTipJar.emoji[product.id, default: "🙂"]
                            Text(verbatim: "\(emoji) \(product.displayPrice) \(emoji)")
                                .frame(minWidth: 130)
                        }
                        .disabled(tipJar.status == .purchasing)
                    }
                }
            }

            VStack(spacing: 4) {
                Text("Total amount tipped:")
                Text(verbatim: tipJar.ledger.formattedTotal())
                    .font(.title.weight(.semibold))
                switch tipJar.status {
                case .thanks:
                    Text("Thank you for your support!").font(.caption).foregroundStyle(.secondary)
                case .failed:
                    Text("Purchase failed. Please try again.").font(.caption).foregroundStyle(.red)
                case .idle, .purchasing:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .task { await tipJar.loadProducts() }
    }
}

struct ReviewButton: View {
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        Button("Review MicDrop") { requestReview() }
            .frame(maxWidth: .infinity)
    }
}
#endif
