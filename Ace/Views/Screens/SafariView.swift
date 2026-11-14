import SwiftUI
import SafariServices

/// The in-app browser Ace uses to open tabs.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredControlTintColor = UIColor(red: 0.36, green: 0.71, blue: 1, alpha: 1)
        vc.preferredBarTintColor = UIColor(red: 0.04, green: 0.04, blue: 0.07, alpha: 1)
        vc.dismissButtonStyle = .close
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
