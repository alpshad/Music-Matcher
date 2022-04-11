import UIKit
import Flutter
import MusicKit
import StoreKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    static let developerToken = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IkoyOTNXWUQ3WVEifQ.eyJpYXQiOjE2NDkyOTIxMDcsImV4cCI6MTY2NDg0NDEwNywiaXNzIjoiM0haVlpHTVNONSJ9.T37bFWgg9gph3zEQF1qgEf7I83wws13-V8ZRQbtzj4nMLylyFH321rbAgk9BAc8E88jiimYn37DJtsaIiN19jg"
    
    static var cloudServiceController = SKCloudServiceController()
    static var cloudServiceCapabilities = SKCloudServiceCapability()
    static var token = ""
    
    override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
      let appleMusicAuthChannel = FlutterMethodChannel(name: "apple-music.musicmatcher/auth", binaryMessenger: controller.binaryMessenger)
      
          appleMusicAuthChannel.setMethodCallHandler({(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
              guard call.method == "appleMusicAuth" else {
                  result(FlutterMethodNotImplemented)
                  return
              }
              
              DispatchQueue.main.async {
                  if #available(iOS 13.0.0, *) {
                      Task {
                        await AppDelegate.appleMusicAuth(result: result)
                        result(AppDelegate.token)
                      }
                  } else {
                      // Fallback on earlier versions
                      result(FlutterError(code: "UNAVAILABLE",
                                              message: "Apple Music Authentication Not Available",
                                              details: nil))
                  }
              }
          })
      
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    @available(iOS 13.0.0, *)
    private static func appleMusicAuth(result: FlutterResult) async {
        if #available(iOS 15.0, *) {
            let task = Task { () -> MusicAuthorization.Status in
                let musicAuthorizationStatus = await MusicAuthorization.request()
                return musicAuthorizationStatus
            }
            let status = await(task.value)
            if status == MusicAuthorization.Status.authorized {
                let provider = MusicUserTokenProvider.init()
                do {
                    token = try await provider.userToken(for: developerToken, options: MusicTokenRequestOptions.init())
                } catch {
                    print("Token Denied")
                    result(FlutterError(code: "UNAUTHORIZED",
                                            message: "Apple Music Authentication Denied",
                                            details: nil))
                }
            }
            else {
                result(FlutterError(code: "UNAUTHORIZED",
                                        message: "Apple Music Authentication Denied",
                                        details: nil))
            }
        } else {
            // Fallback on earlier versions
            result(FlutterError(code: "UNAVAILABLE",
                                    message: "Apple Music Authentication Not Available",
                                    details: nil))
        }
    }
    
}
