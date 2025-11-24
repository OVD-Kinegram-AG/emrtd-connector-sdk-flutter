import Foundation
import KinegramEmrtdConnector

struct ConnectorConfiguration {
  let clientId: String
  let serverURL: URL
  let validationId: String
}

enum ConnectorAccessMode {
  case mrz(documentNumber: String, dateOfBirth: String, dateOfExpiry: String)
  case can(can: String)
}

enum ConnectorFlowError: LocalizedError, Equatable {
  case invalidDateFormat(field: String)
  case cancelled
  case encodingFailed

  var errorDescription: String? {
    switch self {
    case .invalidDateFormat(let field):
      return "Invalid \(field) format. Expected YYMMDD or YYYY-MM-DD."
    case .cancelled:
      return "User cancelled"
    case .encodingFailed:
      return "Failed to encode validation result."
    }
  }
}

@MainActor
final class ConnectorFlow {
  var onCompletion: ((Result<String, Error>) -> Void)?

  private let configuration: ConnectorConfiguration
  private let accessMode: ConnectorAccessMode

  private var connector: EmrtdConnector?
  private var validationTask: Task<Void, Never>?
  private var didFinish = false

  init(configuration: ConnectorConfiguration, accessMode: ConnectorAccessMode) {
    self.configuration = configuration
    self.accessMode = accessMode
  }

  func start() {
    guard validationTask == nil else { return }
    validationTask = Task { [weak self] in
      guard let self else { return }
      await self.runValidationFlow()
    }
  }

  func cancel() {
    guard !didFinish else { return }
    validationTask?.cancel()
    Task { [weak self] in
      guard let self else { return }
      await self.connector?.disconnect()
      self.finish(with: .failure(ConnectorFlowError.cancelled))
    }
  }

  private func runValidationFlow() async {
    let connector = EmrtdConnector(
      serverURL: configuration.serverURL,
      validationId: configuration.validationId,
      clientId: configuration.clientId
    )
    self.connector = connector
    connector.delegate = self

    do {
      let accessKey = try buildAccessKey(for: accessMode)
      let validationResult = try await connector.validate(with: accessKey)
      try finish(with: validationResult)
    } catch is CancellationError {
      finish(with: .failure(ConnectorFlowError.cancelled))
    } catch {
      finish(with: .failure(error))
    }
  }

  private func buildAccessKey(for mode: ConnectorAccessMode) throws -> AccessKey {
    switch mode {
    case .can(let can):
      let digitsOnly = can.trimmingCharacters(in: .whitespacesAndNewlines)
        .components(separatedBy: CharacterSet.decimalDigits.inverted)
        .joined()
      return CANKey(can: digitsOnly)
    case let .mrz(documentNumber, dateOfBirth, dateOfExpiry):
      return try MRZKey(
        documentNumber: documentNumber
          .trimmingCharacters(in: .whitespacesAndNewlines)
          .uppercased(),
        birthDateyyMMdd: try normalizeDateInput(dateOfBirth, field: "date of birth"),
        expiryDateyyMMdd: try normalizeDateInput(dateOfExpiry, field: "date of expiry")
      )
    }
  }

  private func normalizeDateInput(_ value: String, field: String) throws -> String {
    let digits = value.trimmingCharacters(in: .whitespacesAndNewlines)
      .components(separatedBy: CharacterSet.decimalDigits.inverted)
      .joined()

    if digits.count == 6 {
      return digits
    }

    if digits.count == 8 {
      return String(digits.suffix(6))
    }

    throw ConnectorFlowError.invalidDateFormat(field: field)
  }

  private func finish(with result: ValidationResult) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]

    let data = try encoder.encode(result)
    guard let jsonString = String(data: data, encoding: .utf8) else {
      throw ConnectorFlowError.encodingFailed
    }

    finish(with: .success(jsonString))
  }

  private func finish(with result: Result<String, Error>) {
    guard !didFinish else { return }
    didFinish = true
    validationTask?.cancel()
    validationTask = nil
    connector?.delegate = nil
    connector = nil
    onCompletion?(result)
  }

  private func finish(with error: Error) {
    finish(with: .failure(error))
  }
}

extension ConnectorFlow: EmrtdConnectorDelegate {
  func connectorDidCompleteValidation(_ connector: EmrtdConnector, result: ValidationResult) async {
    do {
      try finish(with: result)
    } catch {
      finish(with: error)
    }
  }

  func connector(_ connector: EmrtdConnector, didFailWithError error: Error) async {
    finish(with: error)
  }
}
