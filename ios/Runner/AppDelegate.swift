import Flutter
import UIKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    application.registerForRemoteNotifications()
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PiggyQrExport")!
    FlutterMethodChannel(name: "com.sharablepiggy.app/qr", binaryMessenger: registrar.messenger())
      .setMethodCallHandler { call, result in
        guard call.method == "saveQr" else { result(FlutterMethodNotImplemented); return }
        guard let bytes = call.arguments as? FlutterStandardTypedData else {
          result(FlutterError(code: "invalid_image", message: "Missing QR image", details: nil)); return
        }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
          guard status == .authorized || status == .limited else {
            DispatchQueue.main.async { result(FlutterError(code: "permission_denied", message: "Allow photo access in Settings", details: nil)) }
            return
          }
          PHPhotoLibrary.shared().performChanges({
            PHAssetCreationRequest.forAsset().addResource(with: .photo, data: bytes.data, options: nil)
          }) { success, error in
            DispatchQueue.main.async {
              if success { result(nil) }
              else { result(FlutterError(code: "save_failed", message: error?.localizedDescription, details: nil)) }
            }
          }
        }
      }
  }
}
