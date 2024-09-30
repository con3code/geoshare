import Flutter
import UIKit
import GoogleMaps //追加
import background_locator_2 //追加

func registerPlugins(registry: FlutterPluginRegistry) -> () {
    if (!registry.hasPlugin("BackgroundLocatorPlugin")) {
        GeneratedPluginRegistrant.register(with: registry)
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey(Env.googleMapApiKey)  //追加
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
