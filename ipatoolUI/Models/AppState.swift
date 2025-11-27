import SwiftUI

enum Feature: String, CaseIterable, Identifiable {
    case auth
    case search
    case purchase
    case listVersions
    case download
    case metadata
    case logs
    case settings
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auth: return String(localized: "feature.auth")
        case .search: return String(localized: "feature.search")
        case .purchase: return String(localized: "feature.purchase")
        case .listVersions: return String(localized: "feature.versions")
        case .download: return String(localized: "feature.download")
        case .metadata: return String(localized: "feature.metadata")
        case .logs: return String(localized: "feature.logs")
        case .settings: return String(localized: "feature.settings")
        case .about: return String(localized: "feature.about")
        }
    }

    var icon: String {
        switch self {
        case .auth: return "person.badge.key"
        case .search: return "magnifyingglass"
        case .purchase: return "cart"
        case .listVersions: return "list.number"
        case .download: return "arrow.down.circle"
        case .metadata: return "info.circle"
        case .logs: return "note.text"
        case .settings: return "gear"
        case .about: return "info.square"
        }
    }
}

struct Preferences: Codable, Equatable {
    enum OutputFormat: String, Codable, CaseIterable, Identifiable {
        case text
        case json

        var id: String { rawValue }
    }

    var ipatoolPath: String
    var nonInteractive: Bool
    var verboseLogs: Bool
    var outputFormat: OutputFormat
    var keychainPassphrase: String

    static let `default` = Preferences(
        ipatoolPath: IpatoolService.defaultExecutablePath ?? "/usr/local/bin/ipatool",
        nonInteractive: true,
        verboseLogs: false,
        outputFormat: .json,
        keychainPassphrase: ""
    )
}

struct CommandEnvironment {
    let service: IpatoolService
    let preferences: Preferences
    let logger: CommandLogger
}

@MainActor
final class AppState: ObservableObject {
    @Published var preferences: Preferences {
        didSet {
            PreferencesStore.shared.save(preferences)
        }
    }

    @Published var selectedFeature: Feature = .auth

    let service = IpatoolService()
    let commandLogger = CommandLogger()
    let authViewModel = AuthViewModel()
    let searchViewModel = SearchViewModel()
    let downloadViewModel = DownloadViewModel()
    let listVersionsViewModel = ListVersionsViewModel()
    let versionMetadataViewModel = VersionMetadataViewModel()

    init() {
        preferences = PreferencesStore.shared.load()

        Task { [weak self] in
            guard let self else { return }
            self.authViewModel.bootstrap(using: self.environmentSnapshot())
        }
    }

    func environmentSnapshot() -> CommandEnvironment {
        CommandEnvironment(service: service, preferences: preferences, logger: commandLogger)
    }
}

struct PreferencesStore {
    static let shared = PreferencesStore()

    private let storageKey = "com.dave.ipatoolui.preferences"

    func load() -> Preferences {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode(Preferences.self, from: data)
        else {
            return Preferences.default
        }

        return decoded
    }

    func save(_ preferences: Preferences) {
        guard let data = try? JSONEncoder().encode(preferences) else {
            return
        }

        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
