import SwiftUI
import AppKit

struct SearchView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: SearchViewModel

    init(viewModel: SearchViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox(String(localized: "search.title")) {
                VStack(alignment: .leading) {
                    TextField(String(localized: "search.searchTerm"), text: $viewModel.term)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(search)
                    HStack {
                        Text("search.limit \(Int(viewModel.limit))")
                        Slider(value: $viewModel.limit, in: 1...25, step: 1)
                            .frame(maxWidth: 200)
                        Spacer()
                        Button(action: search) {
                            if viewModel.isSearching {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label(String(localized: "common.search"), systemImage: "magnifyingglass")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }

            if let feedback = viewModel.feedback {
                Text(feedback)
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

            List(viewModel.results) { app in
                HStack(alignment: .top, spacing: 12) {
                    iconView(for: viewModel.artworkURL(for: app))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(app.name ?? String(localized: "common.unknown"))
                                .font(.headline)
                            Spacer()
                            if let price = app.price {
                                Text(String(format: "$%.2f", price))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Text(app.bundleID ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            if let version = app.version {
                                Text("search.version \(version)")
                                    .font(.caption)
                            }
                            if let trackID = app.trackID {
                                Text("search.id \(trackID)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let bundleID = app.bundleID {
                                Button(String(localized: "search.copyBundleId")) {
                                    copyToPasteboard(bundleID)
                                }
                                .buttonStyle(.bordered)
                            }
                            if viewModel.isPurchased(app: app) {
                                Text("search.purchased")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(8)
                            } else if viewModel.isCheckingPurchase(for: app) {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Button(String(localized: "search.purchase")) {
                                    viewModel.purchase(bundleID: app.bundleID, environment: appState.environmentSnapshot())
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
                .task(id: app.id) {
                    await viewModel.ensurePurchaseStatus(for: app, environment: appState.environmentSnapshot())
                }
            }
            .listStyle(.plain)
        }
    }

    private func search() {
        viewModel.search(using: appState.environmentSnapshot())
    }

    private func copyToPasteboard(_ value: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        #endif
    }

    private func iconView(for url: URL?) -> some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        placeholderIcon
                    @unknown default:
                        placeholderIcon
                    }
                }
            } else {
                placeholderIcon
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var placeholderIcon: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.secondary.opacity(0.2))
            .overlay {
                Image(systemName: "app.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        SearchView(viewModel: appState.searchViewModel)
            .environmentObject(appState)
    }
}
