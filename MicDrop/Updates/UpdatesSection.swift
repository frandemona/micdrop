#if !APPSTORE
import SwiftUI

struct UpdatesSection: View {
    let updater: Updater

    var body: some View {
        @Bindable var updater = updater
        GroupBox {
            HStack {
                Toggle("Automatically check for updates", isOn: $updater.automaticallyChecksForUpdates)
                Spacer()
                Button("Check for Updates…") { updater.checkForUpdates() }
            }
            .padding(6)
        } label: {
            Text("Updates")
        }
    }
}
#endif
