import Foundation

@MainActor
final class VersionMetadataViewModel: ObservableObject {
    @Published var appIDString: String = ""
    @Published var bundleIdentifier: String = ""
    @Published var externalVersionID: String = ""
    @Published var details: VersionMetadataLogEvent?
    @Published var isLoading: Bool = false
    @Published var activeError: IpatoolError?

    func fetch(using environment: CommandEnvironment) {
        guard !externalVersionID.trimmingCharacters(in: .whitespaces).isEmpty else {
            activeError = .invalidInput(String(localized: "metadata.provideVersionId"))
            return
        }

        guard validateInput() else {
            activeError = .invalidInput(String(localized: "metadata.provideAppIdOrBundle"))
            return
        }

        isLoading = true
        activeError = nil

        Task { [weak self] in
            guard let self else { return }
            do {
                var command = ["get-version-metadata", "--external-version-id", self.externalVersionID]
                if let appID = Int64(self.appIDString) {
                    command.append(contentsOf: ["--app-id", String(appID)])
                }
                if !self.bundleIdentifier.trimmingCharacters(in: .whitespaces).isEmpty {
                    command.append(contentsOf: ["--bundle-identifier", self.bundleIdentifier])
                }

                let result = try await environment.service.execute(subcommand: command, environment: environment)
                let payload: VersionMetadataLogEvent = try environment.service.decodeEvent(VersionMetadataLogEvent.self, from: result.stdout)
                self.details = payload
            } catch let error as IpatoolError {
                self.activeError = error
            } catch {
                self.activeError = .commandFailed(error.localizedDescription)
            }

            self.isLoading = false
        }
    }

    private func validateInput() -> Bool {
        if let _ = Int64(appIDString), !appIDString.isEmpty {
            return true
        }
        return !bundleIdentifier.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
