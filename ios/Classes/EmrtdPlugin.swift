import Flutter
import UIKit

@MainActor
public class EmrtdPlugin: NSObject, FlutterPlugin {
  private var pendingResult: FlutterResult?
  private weak var presentedController: UIViewController?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "emrtd", binaryMessenger: registrar.messenger())
    let instance = EmrtdPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "readAndVerify":
      guard let arguments = call.arguments as? [String: Any] else {
        result(FlutterError(code: "ARGUMENT_ERROR", message: "Arguments missing or invalid", details: nil))
        return
      }
      handleMRZRequest(arguments: arguments, result: result)

    case "readAndVerifyWithCan":
      guard let arguments = call.arguments as? [String: Any] else {
        result(FlutterError(code: "ARGUMENT_ERROR", message: "Arguments missing or invalid", details: nil))
        return
      }
      handleCANRequest(arguments: arguments, result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleMRZRequest(arguments: [String: Any], result: @escaping FlutterResult) {
    guard
      let configuration = parseConfiguration(arguments: arguments),
      let documentNumber = arguments["documentNumber"] as? String,
      let dateOfBirth = arguments["dateOfBirth"] as? String,
      let dateOfExpiry = arguments["dateOfExpiry"] as? String
    else {
      result(FlutterError(code: "ARGUMENT_MISSING", message: "Missing MRZ parameters", details: nil))
      return
    }

    presentConnector(
      configuration: configuration,
      accessMode: .mrz(
        documentNumber: documentNumber,
        dateOfBirth: dateOfBirth,
        dateOfExpiry: dateOfExpiry
      ),
      result: result
    )
  }

  private func handleCANRequest(arguments: [String: Any], result: @escaping FlutterResult) {
    guard
      let configuration = parseConfiguration(arguments: arguments),
      let can = arguments["can"] as? String
    else {
      result(FlutterError(code: "ARGUMENT_MISSING", message: "CAN parameter missing", details: nil))
      return
    }

    presentConnector(
      configuration: configuration,
      accessMode: .can(can: can),
      result: result
    )
  }

  private func parseConfiguration(arguments: [String: Any]) -> ConnectorConfiguration? {
    guard
      let clientId = arguments["clientId"] as? String,
      let validationUri = arguments["validationUri"] as? String,
      let validationId = arguments["validationId"] as? String,
      let url = URL(string: validationUri)
    else {
      return nil
    }

    return ConnectorConfiguration(clientId: clientId, serverURL: url, validationId: validationId)
  }

  private func presentConnector(
    configuration: ConnectorConfiguration,
    accessMode: ConnectorAccessMode,
    result: @escaping FlutterResult
  ) {
    guard pendingResult == nil else {
      result(FlutterError(code: "BUSY", message: "Another validation is already in progress", details: nil))
      return
    }

    guard let presenter = topViewController() else {
      result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Unable to find a presenter view controller", details: nil))
      return
    }

    let connectorController = ConnectorViewController(configuration: configuration, accessMode: accessMode)
    connectorController.onCompletion = { [weak self] controllerResult in
      self?.handleConnectorCompletion(controllerResult)
    }

    let navigationController = UINavigationController(rootViewController: connectorController)
    navigationController.modalPresentationStyle = .fullScreen
    navigationController.isModalInPresentation = true

    pendingResult = result
    presentedController = navigationController
    presenter.present(navigationController, animated: true)
  }

  private func handleConnectorCompletion(_ controllerResult: Result<String, Error>) {
    guard let flutterResult = pendingResult else { return }

    let sendResult = {
      switch controllerResult {
      case .success(let payload):
        flutterResult(payload)
      case .failure(let error):
        if let flowError = error as? ConnectorFlowError, flowError == .cancelled {
          flutterResult(FlutterError(code: "CANCELLED", message: flowError.localizedDescription, details: nil))
        } else {
          flutterResult(FlutterError(code: "IOS_ERROR", message: error.localizedDescription, details: nil))
        }
      }
    }

    let cleanup = {
      self.pendingResult = nil
      self.presentedController = nil
    }

    if let controller = presentedController {
      controller.dismiss(animated: true) {
        sendResult()
        cleanup()
      }
    } else {
      sendResult()
      cleanup()
    }
  }

  private func topViewController(base: UIViewController? = UIApplication.shared.connectedScenes
    .compactMap { $0 as? UIWindowScene }
    .flatMap { $0.windows }
    .first(where: { $0.isKeyWindow })?.rootViewController) -> UIViewController? {
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
}
