import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: AuthViewModel

    init(viewModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section(String(localized: "auth.appleId")) {
                TextField(String(localized: "auth.email"), text: $viewModel.email)
                    .textContentType(.username)
                    .autocorrectionDisabled()
                SecureField(String(localized: "auth.password"), text: $viewModel.password)
                TextField(String(localized: "auth.2faCode"), text: $viewModel.authCode)
                    .textFieldStyle(.roundedBorder)
            }

            Section(String(localized: "auth.actions")) {
                HStack {
                    Button(String(localized: "auth.signIn"), action: signIn)
                        .disabled(viewModel.isWorking)
                    Button(String(localized: "auth.accountInfo"), action: fetchInfo)
                        .disabled(viewModel.isWorking)
                    Button(String(localized: "auth.revoke"), action: revoke)
                        .disabled(viewModel.isWorking)
                }
            }

            Section(String(localized: "common.status")) {
                Text(viewModel.statusMessage)
                    .font(.callout)
                if viewModel.isWorking {
                    ProgressView()
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
        .formStyle(.grouped)
        .onAppear {
            viewModel.bootstrap(using: appState.environmentSnapshot())
        }
    }

    private func signIn() {
        viewModel.login(using: appState.environmentSnapshot())
    }

    private func fetchInfo() {
        viewModel.fetchInfo(using: appState.environmentSnapshot())
    }

    private func revoke() {
        viewModel.revoke(using: appState.environmentSnapshot())
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        AuthView(viewModel: appState.authViewModel)
            .environmentObject(appState)
    }
}
