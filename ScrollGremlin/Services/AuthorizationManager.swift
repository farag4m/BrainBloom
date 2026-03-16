import FamilyControls
import Combine
import SwiftUI

@MainActor
public final class AuthorizationManager: ObservableObject {
    @Published public var status: AuthorizationStatus = .notDetermined

    public enum AuthorizationStatus: Equatable {
        case notDetermined
        case authorized
        case denied
    }

    public static let shared = AuthorizationManager()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        refreshStatus()

        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.refreshStatus() }
            .store(in: &cancellables)
    }

    public func refreshStatus() {
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved:
            status = .authorized
        case .denied:
            status = .denied
        default:
            status = .notDetermined
        }
    }

    public func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            status = .authorized
        } catch {
            status = .denied
            AppLogger.log(error: error, context: "Authorization request failed", category: "Authorization")
        }
    }

    public func revokeAuthorization() {
        AuthorizationCenter.shared.revokeAuthorization { _ in }
        status = .denied
    }
}
