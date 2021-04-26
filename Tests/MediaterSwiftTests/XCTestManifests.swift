import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(Mediater_SwiftTests.allTests),
    ]
}
#endif
