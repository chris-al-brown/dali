import Foundation
import XCTest
import DaliCore

let single = """
"This is a string"
"""

let multiline = """
"This is a string
"
"""

class ScannerTests: XCTestCase {
    
    func testSingleString() throws {
        let scanner = Scanner(single)
        let _ = try scanner.scan()
    }

    func testMultilineString() throws {
        let scanner = Scanner(multiline)
        do {
            let _ = try scanner.scan()
        } catch let error as ScannerError {
            ///
        } catch _ {
            XCTFail()
        }
    }
}
