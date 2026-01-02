import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL?
    /// Changes to this token force a reload even if the URL is unchanged.
    /// This matters because our preview URL can stay the same across builds
    /// (same sandbox/host), but the content behind it changes.
    let reloadToken: UUID
    @Binding var isLoading: Bool
    @Binding var loadError: String?

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = true
        webView.isOpaque = false
        webView.backgroundColor = UIColor(Color.bgPrimary)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url else { return }

        // Reload if either:
        // - URL changed, or
        // - reloadToken changed (force reload even when URL is identical)
        if context.coordinator.lastLoadedURL != url || context.coordinator.lastReloadToken != reloadToken {
            loadError = nil
            context.coordinator.lastLoadedURL = url
            context.coordinator.lastReloadToken = reloadToken

            let request = URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalCacheData,
                timeoutInterval: 30
            )
            webView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var lastLoadedURL: URL? = nil
        var lastReloadToken: UUID? = nil

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            parent.loadError = nil
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.loadError = nil
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            // Surface HTTP errors (e.g., 502 sandbox not found) as a visible overlay,
            // otherwise WKWebView can look "blank" on dark backgrounds.
            if let http = navigationResponse.response as? HTTPURLResponse {
                if http.statusCode >= 400 {
                    parent.loadError = "HTTP \(http.statusCode): \(HTTPURLResponse.localizedString(forStatusCode: http.statusCode))"
                } else {
                    parent.loadError = nil
                }
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.loadError = error.localizedDescription
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.loadError = error.localizedDescription
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            parent.isLoading = false
            parent.loadError = "Web content process terminated. Tap reload."
        }
    }
}
