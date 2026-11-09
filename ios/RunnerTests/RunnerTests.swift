import Flutter
import UIKit
import XCTest

class RunnerTests: XCTestCase {

  func testDairaCallbackSchemeIsRegistered() {
    let types = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]]
    let schemes = types?.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] } ?? []
    XCTAssertTrue(schemes.contains("daira"))
  }

}
