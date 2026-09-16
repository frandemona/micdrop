import SwiftUI

struct MicButton: View {
    let isMuted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(Color.white)
                Circle().strokeBorder(Color.accentColor.opacity(isMuted ? 0.45 : 1), lineWidth: 6)
                Image(systemName: isMuted ? "mic.slash.fill" : "mic.fill")
                    .font(.system(size: 64, weight: .medium))
                    .foregroundStyle(isMuted ? Color(white: 0.2) : Color.accentColor)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: 180, height: 180)
            .shadow(color: Color.accentColor.opacity(isMuted ? 0 : 0.35), radius: 8)
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .accessibilityLabel(Text("Toggle microphone"))
        .accessibilityValue(isMuted ? Text("Microphone OFF") : Text("Microphone ON"))
    }
}
