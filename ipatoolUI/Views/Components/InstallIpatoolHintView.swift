import SwiftUI
#if os(macOS)
import AppKit
#endif

struct InstallIpatoolHintView: View {
    private let command = "brew install ipatool"

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("hint.notInstalled")
                .font(.callout)
            Text("hint.runCommand")
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack {
                Text(command)
                    .font(.system(.footnote, design: .monospaced))
                    .padding(6)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                Button(String(localized: "common.copy")) {
                    copyCommand()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }

    private func copyCommand() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: .string)
        #endif
    }
}
