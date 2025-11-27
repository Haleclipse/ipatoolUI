import SwiftUI

struct PurchaseView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = PurchaseViewModel()

    var body: some View {
        Form {
            Section(String(localized: "purchase.app")) {
                TextField(String(localized: "purchase.bundleIdentifier"), text: $viewModel.bundleIdentifier)
                    .textFieldStyle(.roundedBorder)
            }

            Section {
                Button(action: purchase) {
                    if viewModel.isProcessing {
                        ProgressView()
                    } else {
                        Label(String(localized: "purchase.purchaseLicense"), systemImage: "checkmark.seal")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isProcessing)
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

    private func purchase() {
        viewModel.purchase(using: appState.environmentSnapshot())
    }
}
