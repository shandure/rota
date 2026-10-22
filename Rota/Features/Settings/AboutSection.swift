import SwiftUI

/// Version, rate, feedback and the privacy line (§4.4).
struct AboutSection: View {
    /// Set once the app exists in App Store Connect.
    static let appStoreID = "0000000000"
    static let feedbackAddress = "rotashiftapp@gmail.com"

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    private var reviewURL: URL? {
        URL(string: "https://apps.apple.com/app/id\(Self.appStoreID)?action=write-review")
    }

    private var feedbackURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Self.feedbackAddress
        components.queryItems = [URLQueryItem(name: "subject", value: "Rota feedback (\(version))")]
        return components.url
    }

    var body: some View {
        Section {
            LabeledContent("Version", value: version)
            if let reviewURL {
                Link("Rate on the App Store", destination: reviewURL)
            }
            if let feedbackURL {
                Link("Send feedback", destination: feedbackURL)
            }
        } header: {
            Text("About")
        } footer: {
            Text("All your data stays on this phone.")
        }
    }
}
