// import UIKit
// import Flutter
// import GoogleMaps
// import UserNotifications
//
// @main
// @objc class AppDelegate: FlutterAppDelegate {
//     override func application(
//         _ application: UIApplication,
//         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//     ) -> Bool {
//         GMSServices.provideAPIKey("AIzaSyBJZk_Ory9ng9gAyhWozklHA7xN1KtgBtk")
//         GeneratedPluginRegistrant.register(with: self)
//
//         if #available(iOS 10.0, *) {
//             UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
//         }
//
//         registerMapView()
//         return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//     }
//
//
//     private func registerMapView() {
//         weak var registrar = self.registrar(forPlugin: IMMapView.pluginName)
//         let factory = IMMapViewFactory(messenger: registrar!.messenger())
//         registrar!.register(
//             factory,
//             withId: IMMapView.viewID)
//     }
// }

import UIKit
import Flutter
import GoogleMaps
import UserNotifications
import MessageUI

@main
@objc class AppDelegate: FlutterAppDelegate, MFMailComposeViewControllerDelegate {

    private let gmailChannelName = "gmail_sender"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GMSServices.provideAPIKey("AIzaSyBJZk_Ory9ng9gAyhWozklHA7xN1KtgBtk")
        GeneratedPluginRegistrant.register(with: self)

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }

        registerGmailSenderChannel()
        registerMapView()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func registerGmailSenderChannel() {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return
        }

        let channel = FlutterMethodChannel(
            name: gmailChannelName,
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else {
                result([
                    "success": false,
                    "mode": "ios_app_delegate_released",
                    "message": "Không thể xử lý yêu cầu gửi email."
                ])
                return
            }

            switch call.method {
            case "getCapabilities":
                self.getCapabilities(result: result)

            case "composeEmail":
                self.composeEmail(call: call, result: result)

            case "openInstallGmail":
                self.openInstallGmail(result: result)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func getCapabilities(result: FlutterResult) {
        let gmailInstalled = canOpenGmail()
        let canSendMail = MFMailComposeViewController.canSendMail()

        result([
            "platform": "ios",
            "gmailInstalled": gmailInstalled,
            "canUseNativeMail": canSendMail,
            "canUseShareFallback": true,
            "gmailOnly": false,
            "supportsAttachmentWithGmail": false,
            "message": gmailInstalled
                ? "Thiết bị đã cài Gmail."
                : "Thiết bị chưa cài Gmail."
        ])
    }

    private func composeEmail(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result([
                "success": false,
                "mode": "ios_invalid_arguments",
                "message": "Dữ liệu gửi email không hợp lệ."
            ])
            return
        }

        let to = (args["to"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        var recipients = args["recipients"] as? [String] ?? []
        if recipients.isEmpty && !to.isEmpty {
            recipients = [to]
        }

        let subject = (args["subject"] as? String) ?? ""
        let body = (args["body"] as? String) ?? ""

        let attachmentsFromA = args["attachments"] as? [String] ?? []
        let attachmentsFromB = args["attachmentPaths"] as? [String] ?? []
        let attachments = attachmentsFromA.isEmpty ? attachmentsFromB : attachmentsFromA

        if attachments.isEmpty && canOpenGmail() {
            openGmailCompose(
                recipients: recipients,
                subject: subject,
                body: body,
                result: result
            )
            return
        }

        if MFMailComposeViewController.canSendMail() {
            openMailComposer(
                recipients: recipients,
                subject: subject,
                body: body,
                attachments: attachments,
                result: result
            )
            return
        }

        openShareSheet(
            recipients: recipients,
            subject: subject,
            body: body,
            attachments: attachments,
            result: result
        )
    }

    private func canOpenGmail() -> Bool {
        guard let url = URL(string: "googlegmail://") else {
            return false
        }

        return UIApplication.shared.canOpenURL(url)
    }

    private func openGmailCompose(
        recipients: [String],
        subject: String,
        body: String,
        result: @escaping FlutterResult
    ) {
        var components = URLComponents()
        components.scheme = "googlegmail"
        components.host = "co"
        components.queryItems = [
            URLQueryItem(name: "to", value: recipients.joined(separator: ",")),
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]

        guard let url = components.url else {
            result([
                "success": false,
                "mode": "ios_invalid_gmail_url",
                "message": "Không tạo được đường dẫn mở Gmail."
            ])
            return
        }

        UIApplication.shared.open(url) { success in
            result([
                "success": success,
                "mode": success ? "ios_opened_gmail" : "ios_open_gmail_failed",
                "message": success
                    ? "Đã mở Gmail. Vui lòng kiểm tra nội dung và bấm Gửi."
                    : "Không mở được Gmail."
            ])
        }
    }

    private func openMailComposer(
        recipients: [String],
        subject: String,
        body: String,
        attachments: [String],
        result: @escaping FlutterResult
    ) {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients(recipients)
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)

        for path in attachments {
            let url = URL(fileURLWithPath: path)

            guard FileManager.default.fileExists(atPath: url.path) else {
                continue
            }

            do {
                let data = try Data(contentsOf: url)
                let mimeType = mimeTypeForFile(url: url)
                let fileName = url.lastPathComponent.isEmpty
                    ? "attachment.jpg"
                    : url.lastPathComponent

                composer.addAttachmentData(
                    data,
                    mimeType: mimeType,
                    fileName: fileName
                )
            } catch {
                continue
            }
        }

        guard let topController = topViewController() else {
            result([
                "success": false,
                "mode": "ios_no_top_controller",
                "message": "Không tìm thấy màn hình hiện tại để mở Mail Composer."
            ])
            return
        }

        topController.present(composer, animated: true)

        result([
            "success": true,
            "mode": "ios_opened_mail_composer",
            "message": "Đã mở ứng dụng Mail để gửi kèm ảnh. Vui lòng kiểm tra nội dung và bấm Gửi."
        ])
    }

    private func openShareSheet(
        recipients: [String],
        subject: String,
        body: String,
        attachments: [String],
        result: @escaping FlutterResult
    ) {
        var items: [Any] = []

        let mailText = """
To: \(recipients.joined(separator: ", "))
Subject: \(subject)

\(body)
"""

        items.append(mailText)

        for path in attachments {
            let url = URL(fileURLWithPath: path)

            if FileManager.default.fileExists(atPath: url.path) {
                items.append(url)
            }
        }

        guard let topController = topViewController() else {
            result([
                "success": false,
                "mode": "ios_no_top_controller",
                "message": "Không tìm thấy màn hình hiện tại để mở Share Sheet."
            ])
            return
        }

        let activityController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        if let popover = activityController.popoverPresentationController {
            popover.sourceView = topController.view
            popover.sourceRect = CGRect(
                x: topController.view.bounds.midX,
                y: topController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        topController.present(activityController, animated: true)

        result([
            "success": true,
            "mode": "ios_opened_share_sheet",
            "message": "Đã mở bảng chia sẻ để gửi email kèm ảnh."
        ])
    }

    private func openInstallGmail(result: @escaping FlutterResult) {
        guard let url = URL(string: "https://apps.apple.com/app/gmail-email-by-google/id422689480") else {
            result([
                "success": false,
                "mode": "ios_invalid_gmail_store_url",
                "message": "Không tạo được đường dẫn tải Gmail."
            ])
            return
        }

        UIApplication.shared.open(url) { success in
            result([
                "success": success,
                "mode": success ? "ios_opened_gmail_store" : "ios_open_gmail_store_failed",
                "message": success
                    ? "Đã mở trang tải Gmail."
                    : "Không mở được trang tải Gmail."
            ])
        }
    }

    private func mimeTypeForFile(url: URL) -> String {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "heic":
            return "image/heic"
        case "gif":
            return "image/gif"
        case "pdf":
            return "application/pdf"
        default:
            return "application/octet-stream"
        }
    }

    private func topViewController(
        base: UIViewController? = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    ) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }

        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }

        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }

        return base
    }

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true)
    }

    private func registerMapView() {
        weak var registrar = self.registrar(forPlugin: IMMapView.pluginName)
        let factory = IMMapViewFactory(messenger: registrar!.messenger())
        registrar!.register(
            factory,
            withId: IMMapView.viewID
        )
    }
}