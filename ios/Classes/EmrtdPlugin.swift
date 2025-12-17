import Flutter

@MainActor
public class EmrtdPlugin: NSObject, FlutterPlugin {
  private var pendingResult: FlutterResult?
  private var connectorFlow: ConnectorFlow?

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
    case "readAndVerifyWithPace":
      guard let arguments = call.arguments as? [String: Any] else {
        result(FlutterError(code: "ARGUMENT_ERROR", message: "Arguments missing or invalid", details: nil))
        return
      }
      handlePACERequest(arguments: arguments, result: result)
    case "readAndVerifyWithPacePolling":
      guard let arguments = call.arguments as? [String: Any] else {
        result(FlutterError(code: "ARGUMENT_ERROR", message: "Arguments missing or invalid", details: nil))
        return
      }
      handlePACEPollingRequest(arguments: arguments, result: result)

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

  private func handlePACERequest(arguments: [String: Any], result: @escaping FlutterResult) {
    guard
      let configuration = parseConfiguration(arguments: arguments),
      let canKey = arguments["canKey"] as? String,
      let documentType = arguments["documentType"] as? String,
      let issuingCountry = arguments["issuingCountry"] as? String
    else {
      result(FlutterError(code: "ARGUMENT_MISSING", message: "Missing PACE parameters", details: nil))
      return
    }

    presentConnector(
      configuration: configuration,
      accessMode: .pace(can: canKey, documentType: documentType, issuingCountry: issuingCountry),
      result: result
    )
  }

  private func handlePACEPollingRequest(arguments: [String: Any], result: @escaping FlutterResult) {
    guard
      let configuration = parseConfiguration(arguments: arguments),
      let can = arguments["can"] as? String
    else {
      result(FlutterError(code: "ARGUMENT_MISSING", message: "Missing PACE polling parameters", details: nil))
      return
    }

    presentConnector(
      configuration: configuration,
      accessMode: .pacePolling(can: can),
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

    let flow = ConnectorFlow(configuration: configuration, accessMode: accessMode)
    flow.onCompletion = { [weak self] controllerResult in
      self?.handleConnectorCompletion(controllerResult)
    }

    pendingResult = result
    connectorFlow = flow
    flow.start()
  }

  private func handleConnectorCompletion(_ controllerResult: Result<String, Error>) {
    guard let flutterResult = pendingResult else { return }

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

    pendingResult = nil
    connectorFlow = nil
  }
}
