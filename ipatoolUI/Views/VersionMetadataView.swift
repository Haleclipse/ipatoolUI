import SwiftUI

struct VersionMetadataView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: VersionMetadataViewModel

    init(viewModel: VersionMetadataViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox(String(localized: "metadata.lookup")) {
                VStack(alignment: .leading, spacing: 8) {
                    TextField(String(localized: "metadata.externalVersionId"), text: $viewModel.externalVersionID)
                        .textFieldStyle(.roundedBorder)
                    TextField(String(localized: "download.appId"), text: $viewModel.appIDString)
                        .textFieldStyle(.roundedBorder)
                    TextField(String(localized: "purchase.bundleIdentifier"), text: $viewModel.bundleIdentifier)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        Spacer()
                        Button(action: fetch) {
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Label(String(localized: "metadata.fetchMetadata"), systemImage: "info.circle")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }

            if let details = viewModel.details {
                GroupBox(String(localized: "metadata.result")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("metadata.version \(details.displayVersion ?? String(localized: "common.unknown"))")
                        Text("metadata.externalId \(details.externalVersionID ?? viewModel.externalVersionID)")
                            .font(.callout)
                        if let date = details.releaseDate {
                            Text("metadata.released \(date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.callout)
                        }
                    }
                    .padding()
                }
            }

            if let error = viewModel.activeError {
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

    private func fetch() {
        viewModel.fetch(using: appState.environmentSnapshot())
    }
}

struct VersionMetadataView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        VersionMetadataView(viewModel: appState.versionMetadataViewModel)
            .environmentObject(appState)
    }
}
