import Flutter
import IMMap
import UIKit

class IMMapViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        IMMapView.shared.config(
            with: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )

        return IMMapView.shared
    }

    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class IMMapView: NSObject, FlutterPlatformView {

    static let shared = IMMapView()

    static let viewID = "plugins.where.place/immap_view"
    static let channelID = "plugins.where.place/immap_view_channel"
    static let pluginName = "immap_plugin"

    private var _view: UIView

    private let _mapVC: IMMapViewController!

    private let _navController: UINavigationController

    private var _methodChannel: FlutterMethodChannel?

    override init() {
        // regis intel font for framework
        imRegisterCustomFont()
        print("LongLV --> IMMapViewController.mapViewController()")

        _mapVC = IMMapViewController.mapViewController()

        _navController = UINavigationController(rootViewController: _mapVC)
        _navController.setNavigationBarHidden(true, animated: false)

        _view = _navController.view

        super.init()
        
        _mapVC.delegate = self
    }

    func config(
        with frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        print("LongLV --> config()")

        _view.frame = frame

        if let messenger = messenger {
            _methodChannel = FlutterMethodChannel(
                name: IMMapView.channelID, binaryMessenger: messenger)
            _methodChannel?.setMethodCallHandler(onMethodCall)
        }

        guard let info = args as? [String: Any] else { return }

        if let languageCode = info["language"] as? String {
            IMMapViewModel.shared.setLanguageCode(languageCode)
        }
    }

    func view() -> UIView {
        return _view
    }

    func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        switch call.method {
        case "searchRoute":
            searchRoute(call: call, result: result)
        case "locatePOI":
            locatePOI(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

}

extension IMMapView {

    private func searchRoute(call: FlutterMethodCall, result: FlutterResult) {
        guard let searchRouteInput = call.arguments as? [String: String] else { return }

        IMMapViewModel.shared.direction(from: searchRouteInput["from"], to: searchRouteInput["to"])
    }

    private func locatePOI(call: FlutterMethodCall, result: FlutterResult) {
        guard let locatePOIInput = call.arguments as? [String: String] else { return }

        IMMapViewModel.shared.locate(poi: locatePOIInput["poi"] ?? "")
    }

}

extension IMMapView: IMMapViewControllerDelegate {

    func mapViewControllerShouldClose(vc: IMMapViewController) {
        _methodChannel?.invokeMethod("willCloseMap", arguments: nil)
    }

}
