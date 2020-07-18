import XCTest

import PythonLambdaTests

var tests = [XCTestCaseEntry]()
tests += PythonLambdaTests.allTests()
XCTMain(tests)
