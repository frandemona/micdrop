import AppKit

enum FeedbackMailer {
    static let recipient = "francisco@zereb.ro"

    static func mailtoURL(version: String) -> URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [URLQueryItem(name: "subject", value: "MicDrop Feedback (v\(version))")]
        return components.url!
    }

    static func open(bundle: Bundle = .main) {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        NSWorkspace.shared.open(mailtoURL(version: version))
    }
}
