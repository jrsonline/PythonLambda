//
//  PythonStringLambda.swift
//  PythonKit
//
//  Created by strictlyswift on 2-Jul-20.
//

import PythonKit

/// Represents an executable python lambda as a string.
///
/// The string is Python code which is executed as a lambda.
/// The lambda is converted into a `PythonObject` via `.pythonObject`
///
/// Use this as a 'break glass' when you can't create a suitable function using the `PythonLambda` capability.
///
///  - Example:
///
///        let doubler = PythonStringLambda(lambda: "x:x*2")
///        df.apply( doubler.py )
///
///  - Note: This is not thread safe and operates by creating the lambda in the `__main__` module, with a unique name.
public class PythonStringLambda : PythonConvertible {
    static let main: PythonObject = Python.import("__main__")
    static var lambdaCounter = 0
    private var id: String? = nil
    private let lambda: String
    
    public init(lambda: String) {
        if lambda.starts(with: "lambda") {
            fatalError("Lambda expression must not start 'lambda'. Eg, just 'x:x*3')")
        }
        if !lambda.contains(":") {
            fatalError("Lambda expression must contain ':' to indicate bound variables (eg 'x:x*3'")
        }
        self.lambda = lambda
    }
    
    /// returns an executable object (not the result of the execution)
    public var pythonObject: PythonObject { get {
        if let id = id {
            return Self.main[dynamicMember: id]
        } else {
            id = "lmbstr\(Self.lambdaCounter)"
            Python.execute(
                """
                \(id!) = lambda \(lambda)
                """
            )
            Self.lambdaCounter += 1
            return Self.main[dynamicMember: id!]
        }
    }}
}


