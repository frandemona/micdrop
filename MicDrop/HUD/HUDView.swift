import SwiftUI

struct HUDView: View {
    let isMuted: Bool
    let targetDescription: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: isMuted ? "mic.slash.fill" : "mic.fill")
                .font(.system(size: 80))
            (isMuted ? Text("Mic OFF") : Text("Mic ON"))
                .font(.system(size: 28, weight: .semibold))
            Text(verbatim: targetDescription)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 200, height: 200)
    }
}
