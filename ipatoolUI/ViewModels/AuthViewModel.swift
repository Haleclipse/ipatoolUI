import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var authCode: String = ""
    @Published var statusMessage: String = String(localized: "auth.notAuthenticated")
    @Published var isWorking: Bool = false
    @Published var activeError: IpatoolError?
    private var hasBootstrapped = false

    func login(using environment: CommandEnvironment) {
        guard !email.isEmpty, !password.isEmpty else {
            activeError = .invalidInput(String(localized: "auth.emailPasswordRequired"))
            return
        }

        perform(subcommand: buildLoginCommand(), environment: environment) { service, result in
            let payload: AuthLogEvent = try service.decodeEvent(AuthLogEvent.self, from: result.stdout)
            let accountEmail = payload.email ?? self.email
            self.statusMessage = String(localized: "auth.signedInAs \(accountEmail)")
            self.email = accountEmail
            self.password = ""
            self.authCode = ""
            self.fetchInfo(using: environment, showProgress: false)
        }
    }

    func fetchInfo(using environment: CommandEnvironment, showProgress: Bool = true, suppressErrors: Bool = false) {
        perform(subcommand: ["auth", "info"], environment: environment, showProgress: showProgress, suppressErrors: suppressErrors) { service, result in
            let payload: AuthLogEvent = try service.decodeEvent(AuthLogEvent.self, from: result.stdout)
            let accountEmail = payload.email ?? String(localized: "common.unknown")
            self.statusMessage = String(localized: "auth.activeSession \(accountEmail)")
            if payload.email != nil {
                self.email = accountEmail
            }
        }
    }

    func revoke(using environment: CommandEnvironment) {
        perform(subcommand: ["auth", "revoke"], environment: environment) { _, _ in
            self.statusMessage = String(localized: "auth.credentialsRevoked")
        }
    }

    func bootstrap(using environment: CommandEnvironment) {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true
        fetchInfo(using: environment, showProgress: false, suppressErrors: true)
    }

    private func perform(
        subcommand: [String],
        environment: CommandEnvironment,
        showProgress: Bool = true,
        suppressErrors: Bool = false,
        onSuccess: @escaping (IpatoolService, CommandExecutionResult) throws -> Void
    ) {
        if showProgress {
            isWorking = true
        }
        if !suppressErrors {
            activeError = nil
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await environment.service.execute(subcommand: subcommand, environment: environment)
                try onSuccess(environment.service, result)
            } catch let error as IpatoolError {
                if !suppressErrors {
                    self.activeError = error
                }
            } catch {
                if !suppressErrors {
                    self.activeError = .commandFailed(error.localizedDescription)
                }
            }

            if showProgress {
                self.isWorking = false
            }
        }
    }

    private func buildLoginCommand() -> [String] {
        var arguments = ["auth", "login", "--email", email, "--password", password]
        if !authCode.trimmingCharacters(in: .whitespaces).isEmpty {
            arguments.append(contentsOf: ["--auth-code", authCode])
        }
        return arguments
    }
}
