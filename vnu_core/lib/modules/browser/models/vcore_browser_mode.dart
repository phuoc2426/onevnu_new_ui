/// Cách mở nội dung web dùng chung trong OneVNU.
///
/// - [inAppWebView]: WebView Flutter hiện tại của dự án.
/// - [customTab]: Android Custom Tabs / iOS SFSafariViewController.
/// - [externalBrowser]: chuyển hẳn URL cho trình duyệt ngoài của hệ điều hành.
enum VcoreBrowserMode {
  inAppWebView,
  customTab,
  externalBrowser,
}
