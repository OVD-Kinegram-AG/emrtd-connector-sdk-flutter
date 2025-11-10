import Flutter
import UIKit

public class EmrtdPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "emrtd", binaryMessenger: registrar.messenger())
    let instance = EmrtdPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "read":
      result("TODO")
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
