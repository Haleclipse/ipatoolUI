import SwiftUI
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

struct DownloadView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: DownloadViewModel
    private static let sizeFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = .useMB
        formatter.countStyle = .file
        return formatter
    }()

    init(viewModel: DownloadViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section(String(localized: "download.targetApp")) {
                TextField(String(localized: "download.appId"), text: $viewModel.appIDString)
                    .textFieldStyle(.roundedBorder)
                TextField(String(localized: "purchase.bundleIdentifier"), text: $viewModel.bundleIdentifier)
                    .textFieldStyle(.roundedBorder)
                TextField(String(localized: "download.externalVersionId"), text: $viewModel.externalVersionID)
                    .textFieldStyle(.roundedBorder)
            }

            Section(String(localized: "download.output")) {
                HStack {
                    TextField(String(localized: "download.destinationPath"), text: $viewModel.outputPath)
                        .textFieldStyle(.roundedBorder)
                    Button(String(localized: "download.choose"), action: browseForOutput)
                }
                Toggle(String(localized: "download.autoPurchase"), isOn: $viewModel.shouldAutoPurchase)
            }

            Section {
                Button(action: download) {
                    Label(String(localized: "download.downloadIpa"), systemImage: "arrow.down.circle")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isDownloading)

                if viewModel.isDownloading {
                    VStack(alignment: .leading, spacing: 6) {
                        if let expected = viewModel.expectedBytes {
                            ProgressView(value: Double(viewModel.downloadedBytes), total: Double(expected))
                        } else {
                            ProgressView()
                        }
                        Text(progressLabel())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            }

            if let status = viewModel.statusMessage {
                Section(String(localized: "common.status")) {
                    Text(status)
                        .font(.callout)
                }
            }

            if let error = viewModel.activeError {
                Section(String(localized: "common.error")) {
                    switch error {
                    case .executableNotFound:
                        InstallIpatoolHintView()
                    default:
                        Text(error.localizedDescription)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private func download() {
        viewModel.download(using: appState.environmentSnapshot())
    }

    private func progressLabel() -> String {
        let downloaded = Self.sizeFormatter.string(fromByteCount: viewModel.downloadedBytes)
        if let total = viewModel.expectedBytes {
            let totalString = Self.sizeFormatter.string(fromByteCount: total)
            return "\(downloaded) / \(totalString)"
        }
        return String(localized: "download.downloaded \(downloaded)")
    }

    private func browseForOutput() {
        #if os(macOS)
        viewModel.ensureSuggestedFilename()

        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ??
            FileManager.default.homeDirectoryForCurrentUser
        if #available(macOS 12.0, *) {
            if let ipaType = UTType(filenameExtension: "ipa") ?? UTType(tag: "ipa", tagClass: .filenameExtension, conformingTo: .item) {
                panel.allowedContentTypes = [ipaType]
            } else {
                panel.allowedContentTypes = [.item]
            }
        } else {
            panel.allowedFileTypes = ["ipa"]
        }
        panel.nameFieldStringValue = viewModel.suggestedFilename
        panel.title = String(localized: "download.selectDestination")
        if panel.runModal() == .OK, let url = panel.url {
            viewModel.outputPath = url.path
        }
        #endif
    }
}

struct DownloadView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        DownloadView(viewModel: appState.downloadViewModel)
            .environmentObject(appState)
    }
}
