import SwiftUI

struct AboutView: View {
    private let ipatoolUIRepoURL = URL(string: "https://github.com/Haleclipse/ipatoolUI")!
    private let ipatoolRepoURL = URL(string: "https://github.com/majd/ipatool")!

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("about.title")
                .font(.largeTitle)
                .bold()

            Text("about.description")
                .font(.body)

            VStack(alignment: .leading, spacing: 8) {
                Text("about.credits")
                    .font(.headline)
                Text("about.creditsDescription")
                Link(String(localized: "about.viewIpatoolOnGitHub"), destination: ipatoolRepoURL)
                    .font(.body.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 8) {
                Link(String(localized: "about.viewIpatoolUIOnGitHub"), destination: ipatoolUIRepoURL)
                    .font(.body.weight(.semibold))
            }

            Spacer()
        }
        .padding()
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
