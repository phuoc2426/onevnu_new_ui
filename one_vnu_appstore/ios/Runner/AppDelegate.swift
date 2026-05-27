import UIKit
import Flutter
import GoogleMaps
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GMSServices.provideAPIKey("AIzaSyBJZk_Ory9ng9gAyhWozklHA7xN1KtgBtk")
        GeneratedPluginRegistrant.register(with: self)

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }

        registerMapView()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    
    private func registerMapView() {
        weak var registrar = self.registrar(forPlugin: IMMapView.pluginName)
        let factory = IMMapViewFactory(messenger: registrar!.messenger())
        registrar!.register(
            factory,
            withId: IMMapView.viewID)
    }
}
