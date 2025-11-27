import Foundation

@MainActor
final class DownloadViewModel: ObservableObject {
    @Published var appIDString: String = ""
    @Published var bundleIdentifier: String = ""
    @Published var externalVersionID: String = ""
    @Published var outputPath: String = ""
@Published var shouldAutoPurchase: Bool = false
@Published var isDownloading: Bool = false
@Published var statusMessage: String?
@Published var activeError: IpatoolError?
@Published var downloadedBytes: Int64 = 0
@Published var expectedBytes: Int64?
@Published var suggestedFilename: String = "App.ipa"

private var progressTask: Task<Void, Never>?
private var cachedAppName: String? {
    didSet { updateSuggestedFilename() }
}

    func download(using environment: CommandEnvironment) {
        guard validateInput() else {
            activeError = .invalidInput(String(localized: "download.enterAppIdOrBundle"))
            return
        }

        isDownloading = true
        activeError = nil
        statusMessage = nil
        progressTask?.cancel()

        Task { [weak self] in
            guard let self else { return }
            do {
                let resolvedOutputPath = self.resolveOutputPath()
                self.outputPath = resolvedOutputPath

                self.expectedBytes = await self.fetchExpectedSize()
                self.downloadedBytes = 0
                self.progressTask = Task { [weak self] in
                    await self?.trackProgress(tempPath: "\(resolvedOutputPath).tmp", finalPath: resolvedOutputPath)
                }

                var command = ["download"]
                if let appID = Int64(self.appIDString) {
                    command.append(contentsOf: ["--app-id", String(appID)])
                }
                if !self.bundleIdentifier.trimmingCharacters(in: .whitespaces).isEmpty {
                    command.append(contentsOf: ["--bundle-identifier", self.bundleIdentifier])
                }
                if !self.externalVersionID.trimmingCharacters(in: .whitespaces).isEmpty {
                    command.append(contentsOf: ["--external-version-id", self.externalVersionID])
                }
                command.append(contentsOf: ["--output", resolvedOutputPath])
                if self.shouldAutoPurchase {
                    command.append("--purchase")
                }

                let result = try await environment.service.execute(subcommand: command, environment: environment)
                let payload: DownloadLogEvent = try environment.service.decodeEvent(DownloadLogEvent.self, from: result.stdout)
                if let path = payload.output ?? self.outputPath.nonEmptyOrNil {
                    self.statusMessage = String(localized: "download.succeeded \(path)")
                } else {
                    self.statusMessage = String(localized: "download.succeeded \(self.outputPath)")
                }
            } catch let error as IpatoolError {
                self.activeError = error
            } catch {
                self.activeError = .commandFailed(error.localizedDescription)
            }

            self.progressTask?.cancel()
            self.progressTask = nil
            self.expectedBytes = nil
            self.downloadedBytes = 0
            self.isDownloading = false
        }
    }

    private func validateInput() -> Bool {
        if let _ = Int64(appIDString), !appIDString.isEmpty {
            return true
        }
        return !bundleIdentifier.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func resolveOutputPath() -> String {
        let trimmed = outputPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }

        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ??
            FileManager.default.homeDirectoryForCurrentUser
        ensureSuggestedFilename()
        return downloads.appendingPathComponent(suggestedFilename).path
    }

    private func fetchExpectedSize() async -> Int64? {
        let trimmedBundle = bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedBundle.isEmpty, let app = await lookup(bundleID: trimmedBundle) {
            await MainActor.run {
                if let name = app.trackName?.nonEmptyOrNil {
                    cachedAppName = name
                }
            }
            if let bytes = app.fileSizeBytes, let parsed = Int64(bytes) {
                return parsed
            }
        }
        if let appID = Int64(appIDString), let app = await lookup(appID: appID) {
            await MainActor.run {
                if let name = app.trackName?.nonEmptyOrNil {
                    cachedAppName = name
                }
            }
            if let bytes = app.fileSizeBytes, let parsed = Int64(bytes) {
                return parsed
            }
        }
        return nil
    }

    private func lookup(bundleID: String) async -> LookupResponse.Item? {
        await lookup(parameters: ["bundleId": bundleID])
    }

    private func lookup(appID: Int64) async -> LookupResponse.Item? {
        await lookup(parameters: ["id": String(appID)])
    }

    private func lookup(parameters: [String: String]) async -> LookupResponse.Item? {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        var items = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        items.append(URLQueryItem(name: "country", value: "us"))
        components?.queryItems = items

        guard let url = components?.url else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(LookupResponse.self, from: data)
            return response.results.first
        } catch {
            return nil
        }
    }

    func ensureSuggestedFilename() {
        if let cached = cachedAppName?.nonEmptyOrNil {
            suggestedFilename = sanitize(name: cached)
            return
        }
        if let bundle = bundleIdentifier.nonEmptyOrNil {
            suggestedFilename = sanitize(name: bundle)
            return
        }
        if let appID = appIDString.nonEmptyOrNil {
            suggestedFilename = "App-\(appID).ipa"
            return
        }
        suggestedFilename = "ipatool-download.ipa"
    }

    private func sanitize(name: String) -> String {
        let sanitized = name.replacingOccurrences(of: "[^A-Za-z0-9._-]", with: "-", options: .regularExpression)
        return sanitized.isEmpty ? "ipatool-download.ipa" : "\(sanitized).ipa"
    }

    private func updateSuggestedFilename() {
        ensureSuggestedFilename()
    }

    private func trackProgress(tempPath: String, finalPath: String) async {
        let fileManager = FileManager.default
        while !Task.isCancelled {
            let pathToCheck: String
            if fileManager.fileExists(atPath: tempPath) {
                pathToCheck = tempPath
            } else if fileManager.fileExists(atPath: finalPath) {
                pathToCheck = finalPath
            } else {
                pathToCheck = tempPath
            }

            if let attributes = try? fileManager.attributesOfItem(atPath: pathToCheck),
               let size = attributes[.size] as? NSNumber {
                await MainActor.run {
                    self.downloadedBytes = size.int64Value
                }
            }

            try? await Task.sleep(nanoseconds: 500_000_000)

            let stillRunning = await MainActor.run { self.isDownloading }
            if Task.isCancelled || !stillRunning {
                break
            }
        }
    }

    deinit {
        progressTask?.cancel()
    }
}

private extension String {
    var nonEmptyOrNil: String? {
        let trimmed = trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct LookupResponse: Decodable {
    struct Item: Decodable {
        let fileSizeBytes: String?
        let trackName: String?
    }

    let results: [Item]
}
