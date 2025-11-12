import Foundation
import KinegramEmrtdConnector
import UIKit

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
final class ConnectorViewController: UIViewController {
  var onCompletion: ((Result<String, Error>) -> Void)?

  private let configuration: ConnectorConfiguration
  private let accessMode: ConnectorAccessMode

  private var connector: EmrtdConnector?
  private var validationTask: Task<Void, Never>?
  private var didFinish = false

  private let statusLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 0
    label.textAlignment = .center
    label.text = "Preparing…"
    label.font = .preferredFont(forTextStyle: .body)
    return label
  }()

  private let activityIndicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .large)
    indicator.translatesAutoresizingMaskIntoConstraints = false
    indicator.hidesWhenStopped = false
    indicator.startAnimating()
    return indicator
  }()

  init(configuration: ConnectorConfiguration, accessMode: ConnectorAccessMode) {
    self.configuration = configuration
    self.accessMode = accessMode
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground
    navigationItem.title = "eMRTD"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .close,
      target: self,
      action: #selector(cancelFlow)
    )

    view.addSubview(statusLabel)
    view.addSubview(activityIndicator)

    NSLayoutConstraint.activate([
      statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
      statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
      statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),

      activityIndicator.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 24),
      activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor)
    ])
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    startValidationIfNeeded()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isMovingFromParent || isBeingDismissed {
      validationTask?.cancel()
    }
  }

  private func startValidationIfNeeded() {
    guard validationTask == nil else { return }
    validationTask = Task { [weak self] in
      guard let self else { return }
      await self.runValidationFlow()
    }
  }

  private func runValidationFlow() async {
    updateStatus("Connecting…")
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

  private func updateStatus(_ text: String) {
    statusLabel.text = text
  }

  @objc
  private func cancelFlow() {
    guard !didFinish else { return }
    updateStatus("Cancelling…")
    validationTask?.cancel()
    Task { [weak self] in
      await self?.connector?.disconnect()
      self?.finish(with: .failure(ConnectorFlowError.cancelled))
    }
  }
}

extension ConnectorViewController: EmrtdConnectorDelegate {
  func connectorDidConnect(_ connector: EmrtdConnector) async {
    updateStatus("Connected. Hold the document to the top of the phone.")
  }

  func connectorWillReadChip(_ connector: EmrtdConnector) async {
    updateStatus("Reading the chip… Keep the document steady.")
  }

  func connectorDidPerformHandover(_ connector: EmrtdConnector) async {
    updateStatus("Authenticating with the server…")
  }

  func connectorWillCompleteReading(_ connector: EmrtdConnector) async {
    updateStatus("Finalizing…")
  }

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

  func connector(_ connector: EmrtdConnector, didUpdateNFCStatus status: NFCProgressStatus) async {
    updateStatus(status.alertMessage)
  }
}
