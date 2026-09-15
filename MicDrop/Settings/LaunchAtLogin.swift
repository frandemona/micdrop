import Observation
import ServiceManagement

@Observable
final class LaunchAtLogin {
    @ObservationIgnored private let service: SMAppService
    private var status: SMAppService.Status
    private(set) var errorMessage: String?

    init(service: SMAppService = .mainApp) {
        self.service = service
        status = service.status
    }

    var isEnabled: Bool {
        get { status == .enabled }
        set {
            do {
                if newValue {
                    try service.register()
                } else {
                    try service.unregister()
                }
                errorMessage = nil
            } catch {
                errorMessage = String(localized: "Couldn't change the login item setting.")
            }
            status = service.status
        }
    }

    func refresh() {
        status = service.status
    }
}
