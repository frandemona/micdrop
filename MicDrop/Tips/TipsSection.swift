import SwiftUI

struct TipsSection: View {
    let appState: AppState

    var body: some View {
        #if APPSTORE
        StoreTipsView(tipJar: appState.tipJar)
        #else
        LinkTipsView()
        #endif
    }
}
