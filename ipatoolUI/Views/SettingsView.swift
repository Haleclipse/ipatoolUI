import SwiftUI
#if os(macOS)
import AppKit
#endif

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var detectionMessage: String?

    var body: some View {
        Form {
            Section(String(localized: "settings.ipatoolBinary")) {
                HStack {
                    TextField(String(localized: "settings.pathToIpatool"), text: binding(\.ipatoolPath))
                        .textFieldStyle(.roundedBorder)
                    Button(String(localized: "settings.browse"), action: browseForExecutable)
                    Button(String(localized: "settings.autoDetect"), action: autoDetect)
                }
                if let message = detectionMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section(String(localized: "settings.behavior")) {
                Toggle(String(localized: "settings.nonInteractive"), isOn: binding(\.nonInteractive))
                Toggle(String(localized: "settings.verboseLogs"), isOn: binding(\.verboseLogs))
                Picker(String(localized: "settings.outputFormat"), selection: binding(\.outputFormat)) {
                    ForEach(Preferences.OutputFormat.allCases) { format in
                        Text(format.rawValue.uppercased()).tag(format)
                    }
                }
                SecureField(String(localized: "settings.keychainPassphrase"), text: binding(\.keychainPassphrase))
                    .textFieldStyle(.roundedBorder)
            }
        }
        .formStyle(.grouped)
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<Preferences, Value>) -> Binding<Value> {
        Binding(
            get: { appState.preferences[keyPath: keyPath] },
            set: { appState.preferences[keyPath: keyPath] = $0 }
        )
    }

    private func autoDetect() {
        if let detected = IpatoolService.autoDetectExecutablePath() {
            appState.preferences.ipatoolPath = detected
            detectionMessage = String(localized: "settings.detectedAt \(detected)")
        } else {
            detectionMessage = String(localized: "settings.unableToLocate")
        }
    }

    private func browseForExecutable() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            appState.preferences.ipatoolPath = url.path
            detectionMessage = String(localized: "settings.using \(url.path)")
        }
        #endif
    }
}
