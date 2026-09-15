import SwiftUI

struct PreferencesView: View {
    let appState: AppState

    var body: some View {
        @Bindable var settings = appState.settings
        @Bindable var launchAtLogin = appState.launchAtLogin

        VStack(alignment: .leading, spacing: 16) {
            Text("MicDrop is free, but please leave a tip if you want to see more features!")
                .fixedSize(horizontal: false, vertical: true)

            TipsSection(appState: appState)

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Show HUD on mute/unmute", isOn: $settings.showHUD)
                    Toggle("Launch at Login", isOn: $launchAtLogin.isEnabled)
                    if let message = launchAtLogin.errorMessage {
                        Text(verbatim: message)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
            } label: {
                Text("Settings")
            }

            #if !APPSTORE
            if let updater = appState.updater {
                UpdatesSection(updater: updater)
            }
            #endif

            HStack(spacing: 12) {
                #if APPSTORE
                ReviewButton()
                #endif
                Button("Send Feedback") { FeedbackMailer.open() }
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}
