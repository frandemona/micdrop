import KeyboardShortcuts
import SwiftUI

struct PopoverView: View {
    let appState: AppState
    let openPreferences: () -> Void

    var body: some View {
        @Bindable var appState = appState
        @Bindable var settings = appState.settings

        VStack(spacing: 14) {
            MicButton(isMuted: appState.mic.isMuted) { appState.mic.toggle() }
                .padding(.top, 8)

            (appState.mic.isMuted ? Text("Microphone OFF") : Text("Microphone ON"))
                .font(.title2)
                .foregroundStyle(appState.mic.isMuted ? Color.primary : Color.accentColor)

            Button {
                withAnimation(.snappy) { settings.settingsExpanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Text("SETTINGS")
                    Image(systemName: settings.settingsExpanded ? "chevron.up" : "chevron.down")
                }
                .font(.callout.weight(.medium))
            }
            .buttonStyle(.plain)

            if settings.settingsExpanded {
                Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 10) {
                    GridRow {
                        Text("Device:").gridColumnAlignment(.trailing)
                        Picker("Device:", selection: $appState.deviceTarget) {
                            Text("Default Input Device").tag(DeviceTarget.defaultDevice)
                            Text("All Input Devices").tag(DeviceTarget.allDevices)
                            Divider()
                            ForEach(appState.mic.availableDevices, id: \.uid) { device in
                                Text(verbatim: device.name).tag(DeviceTarget.specific(uid: device.uid))
                            }
                        }
                        .labelsHidden()
                    }
                    GridRow {
                        Text("Mode:")
                        Picker("Mode:", selection: $appState.mode) {
                            Text("Toggle").tag(MicMode.toggle)
                            Text("Push-to-talk").tag(MicMode.pushToTalk)
                        }
                        .labelsHidden()
                    }
                    GridRow {
                        Text("Hotkey:")
                        KeyboardShortcuts.Recorder(for: .toggleMic)
                    }
                }
                .transition(.opacity)
            }

            if !appState.mic.unsupportedDevices.isEmpty {
                Text("Can't mute: \(appState.mic.unsupportedDevices.map(\.name).formatted(.list(type: .and)))")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }

            HStack {
                Button(action: openPreferences) {
                    Image(systemName: "gearshape.fill").font(.title3)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(Text("Preferences"))
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }
        }
        .padding(16)
        .frame(width: 300)
    }
}
