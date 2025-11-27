import Foundation

struct VersionListItem: Identifiable, Equatable {
    let externalVersionID: String
    var displayVersion: String?

    var id: String { externalVersionID }
}

@MainActor
final class ListVersionsViewModel: ObservableObject {
    @Published var appIDString: String = ""
    @Published var bundleIdentifier: String = ""
    @Published private(set) var versionItems: [VersionListItem] = []
    @Published var isLoading: Bool = false
    @Published var activeError: IpatoolError?
    @Published var statusMessage: String?

    func fetch(using environment: CommandEnvironment) {
        guard validateInput() else {
            activeError = .invalidInput(String(localized: "versions.provideAppIdOrBundle"))
            return
        }

        isLoading = true
        activeError = nil
        statusMessage = nil

        Task { [weak self] in
            guard let self else { return }
            defer { self.isLoading = false }
            do {
                let resolvedAppID = Int64(self.appIDString)
                let trimmedBundleID = self.bundleIdentifier.trimmingCharacters(in: .whitespaces)

                var command = ["list-versions"]
                if let appID = resolvedAppID {
                    command.append(contentsOf: ["--app-id", String(appID)])
                }
                if !trimmedBundleID.isEmpty {
                    command.append(contentsOf: ["--bundle-identifier", trimmedBundleID])
                }

                let result = try await environment.service.execute(subcommand: command, environment: environment)
                let payload: VersionsLogEvent = try environment.service.decodeEvent(VersionsLogEvent.self, from: result.stdout)
                let identifiers = payload.externalVersionIdentifiers ?? []
                self.versionItems = identifiers.map { VersionListItem(externalVersionID: $0, displayVersion: nil) }
                self.statusMessage = String(localized: "versions.fetched \(self.versionItems.count)")
                self.startMetadataFetch(
                    identifiers: identifiers,
                    appID: resolvedAppID,
                    bundleID: trimmedBundleID.isEmpty ? nil : trimmedBundleID,
                    environment: environment
                )
            } catch let error as IpatoolError {
                self.activeError = error
            } catch {
                self.activeError = .commandFailed(error.localizedDescription)
            }
        }
    }

    func resumeMetadataFetch(using environment: CommandEnvironment) {
        guard !versionItems.isEmpty else { return }
        let unresolved = versionItems
            .filter { $0.displayVersion == nil }
            .map(\.externalVersionID)
        guard !unresolved.isEmpty else { return }

        let appID = Int64(appIDString)
        let trimmedBundle = bundleIdentifier.trimmingCharacters(in: .whitespaces)
        let bundleID = trimmedBundle.isEmpty ? nil : trimmedBundle

        startMetadataFetch(
            identifiers: unresolved,
            appID: appID,
            bundleID: bundleID,
            environment: environment
        )
    }

    private func startMetadataFetch(
        identifiers: [String],
        appID: Int64?,
        bundleID: String?,
        environment: CommandEnvironment
    ) {
        guard !identifiers.isEmpty else { return }
        guard appID != nil || bundleID != nil else { return }

        Task { [weak self] in
            guard let self else { return }
            await self.populateDisplayVersions(
                identifiers: identifiers,
                appID: appID,
                bundleID: bundleID,
                environment: environment
            )
        }
    }

    private func populateDisplayVersions(
        identifiers: [String],
        appID: Int64?,
        bundleID: String?,
        environment: CommandEnvironment
    ) async {
        for externalID in identifiers {
            var command = ["get-version-metadata", "--external-version-id", externalID]
            if let appID = appID {
                command.append(contentsOf: ["--app-id", String(appID)])
            } else if let bundleID = bundleID {
                command.append(contentsOf: ["--bundle-identifier", bundleID])
            }

            do {
                let result = try await environment.service.execute(subcommand: command, environment: environment)
                let payload: VersionMetadataLogEvent = try environment.service.decodeEvent(VersionMetadataLogEvent.self, from: result.stdout)
                if let displayVersion = payload.displayVersion,
                   let index = versionItems.firstIndex(where: { $0.externalVersionID == externalID }) {
                    versionItems[index].displayVersion = displayVersion
                }
            } catch {
                continue
            }
        }
    }

    private func validateInput() -> Bool {
        if let _ = Int64(appIDString), !appIDString.isEmpty {
            return true
        }
        return !bundleIdentifier.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
