#if !APPSTORE
import SwiftUI

enum TipConfig {
    /// Placeholder — replace with the real tip page before release. `scripts/release-direct.sh` refuses to ship it.
    static let directTipURL = URL(string: "https://example.com/tip-micdrop")!
}

struct LinkTipsView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            openURL(TipConfig.directTipURL)
        } label: {
            Label("Leave a tip", systemImage: "heart.fill")
        }
        .controlSize(.large)
        .frame(maxWidth: .infinity)
    }
}
#endif
