import SwiftUI
#if os(macOS)
import AppKit
#endif

struct ListVersionsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ListVersionsViewModel
    @State private var lastEnvironment: CommandEnvironment?

    init(viewModel: ListVersionsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox(String(localized: "versions.targetApp")) {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    GridRow {
                        Text("versions.appId")
                        TextField("123456", text: $viewModel.appIDString)
                            .textFieldStyle(.roundedBorder)
                    }
                    GridRow {
                        Text("versions.bundleId")
                        TextField("com.example.app", text: $viewModel.bundleIdentifier)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.bottom, 8)
                HStack {
                    Spacer()
                    Button(action: fetch) {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Label(String(localized: "versions.listVersions"), systemImage: "list.number")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if let status = viewModel.statusMessage {
                Text(status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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

            List(viewModel.versionItems) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if let versionName = item.displayVersion {
                            Text(versionName)
                                .font(.headline)
                        } else {
                            Text("versions.loadingVersion")
                                .foregroundStyle(.secondary)
                                .font(.headline)
                        }
                        Text(item.externalVersionID)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(String(localized: "common.copy")) {
                        copyToPasteboard(item.externalVersionID)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .onAppear(perform: resumeIfNeeded)
    }

    private func fetch() {
        viewModel.fetch(using: appState.environmentSnapshot())
    }

    private func resumeIfNeeded() {
        let environment = appState.environmentSnapshot()
        if lastEnvironment == nil {
            lastEnvironment = environment
            return
        }
        if viewModel.versionItems.contains(where: { $0.displayVersion == nil }) {
            viewModel.resumeMetadataFetch(using: environment)
        }
        lastEnvironment = environment
    }

    private func copyToPasteboard(_ value: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        #endif
    }
}

struct ListVersionsView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        ListVersionsView(viewModel: appState.listVersionsViewModel)
            .environmentObject(appState)
    }
}
