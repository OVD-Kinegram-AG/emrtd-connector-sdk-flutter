import Flutter
import UIKit
import XCTest

@testable import emrtd

class RunnerTests: XCTestCase {
  func testGetPlatformVersion() {
    let plugin = EmrtdPlugin()

    let call = FlutterMethodCall(methodName: "read", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual(result as! String, "TODO")
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }
}
