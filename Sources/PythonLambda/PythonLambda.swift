//
//  PythonLambda.swift
//
//
//  Created by strictlyswift on 7/6/20.
//

import PythonKit

/// Allows Swift functions to be represented as Python lambdas. Note that you can use the typealias 𝝺 for `PythonLambda`, as per this documentation, because it looks nice. PythonLambda is only available on Python versions > 3.
///
/// Example:
///
/// The Python code `map(lambda(x:x*2), [10,12,14] )`  could be written as:
///
///         Python.map( 𝝺{x in x*2} , [10,12,14] ) // [20,24,28]
///
///
/// or alternatively, without the special character:
///
///         Python.map( PythonLambda {x in x*2} , [10,12,14] ) // [20,24,28]
///
/// There are a number of limitations, not least that only a select number of function shapes are supported. These are:
/// - (Int) -> Int
/// - (String) -> String
/// - (String) -> Int
/// - (Int) -> String
/// - (Double) -> Double
/// - (Double) -> Int
/// - (Double) -> String
/// - (Int) -> Bool
/// - (String) -> Bool
/// - (Double) -> Bool
/// - (Bool) -> Int
/// - (Bool) -> String
/// - (Bool) -> Double
/// - (Bool) -> Bool
/// - (PythonObject) -> String
/// - (PythonObject) -> Int
/// - (PythonObject) -> Double
/// - (PythonObject) -> Bool
/// - (PythonObject) -> PythonObject
/// - (PythonObject, PythonObject) -> PythonObject
/// - (PythonObject, PythonObject, PythonObject) -> PythonObject
///
/// For additional flexibility, see `PythonStringLambda`.
///
/// Secondly, note that creating a lambda will cause a (small) memory leak. In the *vast* majority of cases, the memory used by a lambda is so small (a few bytes) it's not worth being concerned about.  Where you are concerned about memory leaks, however, eg for large numbers of lambda calls in a loop, there are two solutions:
/// 1. Create the lambda as a named variable before the loop; and then call `dealloc` on the variable afterwards. Eg:
///
///
///        let tripler = 𝝺{x in x*3}  // nb: creating 𝝺 causes a leak
///        for _ in 1...1000 {   df.apply( tripler )  }
///        tripler.dealloc() // stop the leak 🚰
///
/// 2. Use the auto-deallocating function `withDeallocating`, or the equivalent custom operator `>>>`. This allows you to create and apply a lambda to a closure, and automatically deallocates it the lambda once the closure has executed. For example:
///
///
///        for _ in 1...1000 {
///            𝝺{ Int($0) } >>> { m in Python.map(m , [3.4, 2.4, 1.2] )  }
///        }
///
///
///  or exactly equivalently, but without the custom operator and the 𝝺 character:
///
///
///        for _ in 1...1000 {
///            withDeallocating( PythonLambda{ Int($0) }, in: { m in Python.map(m , [3.4, 2.4, 1.2] )  } )
///        }
///
/// Lastly, note that creation of lambdas is *not* thread-safe. Lambdas are created directly into the
/// Python runtime and given a unique identifier. Multi-threading may interrupt the creation of this
/// unique identifier. If you create lambdas on multiple threads you need to synchronize them to ensure
/// the identifier remains unique.
///
public typealias 𝝺 = PythonLambda

/// Allows Swift functions to be represented as Python lambdas. Note that you can use the typealias 𝝺 for `PythonLambda`, as per this documentation, because it looks nice. PythonLambda is only available on Python versions > 3.
///
/// Example:
///
/// The Python code `map(lambda(x:x*2), [10,12,14] )`  would be written as:
///
///         Python.map( 𝝺{x in x*2} , [10,12,14] ) // [20,24,28]
///
///
/// or alternatively, without the special character:
///
///         Python.map( PythonLambda {x in x*2} , [10,12,14] ) // [20,24,28]
///
///
/// There are a number of limitations, not least that only a select number of one-parameter function shapes are supported. These are:
/// - (Int) -> Int
/// - (String) -> String
/// - (String) -> Int
/// - (Int) -> String
/// - (Double) -> Double
/// - (Double) -> Int
/// - (Double) -> String
/// - (Int) -> Bool
/// - (String) -> Bool
/// - (Double) -> Bool
/// - (Bool) -> Int
/// - (Bool) -> String
/// - (Bool) -> Double
/// - (Bool) -> Bool
/// - (PythonObject) -> String
/// - (PythonObject) -> Int
/// - (PythonObject) -> Double
/// - (PythonObject) -> Bool
/// - (PythonObject) -> PythonObject
/// - (PythonObject, PythonObject) -> PythonObject
/// - (PythonObject, PythonObject, PythonObject) -> PythonObject
///
///
/// For additional flexibility, see `PythonStringLambda`.
///
/// Secondly, note that creating a lambda will cause a (small) memory leak. In the *vast* majority of cases, the memory used by a lambda is so small (a few bytes) it's not worth being concerned about. However, where you are concerned about memory leaks, eg for large numbers of lambda calls in a loop, there are two solutions:
/// 1. Create the lambda as a named variable before the loop; and then call `dealloc` on the variable afterwards. Eg:
///
///
///        let tripler = 𝝺{x in x*3}  // nb: creating 𝝺 causes a leak
///        for _ in 1...1000 {   df.apply( tripler )  }
///        tripler.dealloc() // stop the leak 🚰
///
/// 2. Use the auto-deallocating function `withDeallocating`, or the equivalent custom operator `>>>`. This allows you to create and apply a lambda to a closure, and automatically deallocates it the lambda once the closure has executed. For example:
///
///
///        𝝺{ Int($0) } >>> { m in Python.map(m , [3.4, 2.4, 1.2] )  }
///
///
///  or exactly equivalently, but without the custom operator and the 𝝺 character:
///
///
///       withDeallocating( PythonLambda{ Int($0) }, in: { m in Python.map(m , [3.4, 2.4, 1.2] )  } )
///
///
///
/// Lastly, note that creation of lambdas is *not* thread-safe. Lambdas are created directly into the
/// Python runtime and given a unique identifier. Multi-threading may interrupt the creation of this
/// unique identifier. If you create lambdas on multiple threads you need to synchronize them to ensure
/// the identifier remains unique.
///
public class PythonLambda {
    let backend: PythonLambdaSupport
    public let py: PythonObject
    private static var lambdaCounter = 0
    
    private static let lib : PythonCLibrary? = PythonCLibrary()
        
    public init( _ fn: @escaping (Int) -> Int) {
        let name = "lmb\(Self.lambdaUniqueName())"

        self.backend = PythonLambdaSupport(fn, name: name)
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (String) -> String) {
        let name = "lmb\(Self.lambdaUniqueName())"
        self.backend = PythonLambdaSupport(fn, name: name)
        
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (String) -> Int) {
        let name = "lmb\(Self.lambdaUniqueName())"
        self.backend = PythonLambdaSupport(fn, name: name)
        
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (Int) -> String) {
        let name = "lmb\(Self.lambdaUniqueName())"
        self.backend = PythonLambdaSupport(fn, name: name)
        
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }
    
    
    public init( _ fn: @escaping (Double) -> Double) {
        let name = "lmb\(Self.lambdaUniqueName())"
        self.backend = PythonLambdaSupport(fn, name: name)
        
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (Double) -> Int) {
        let name = "lmb\(Self.lambdaUniqueName())"
        self.backend = PythonLambdaSupport(fn, name: name)
        
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (Double) -> String) {
        let name = "lmb\(Self.lambdaUniqueName())"
        self.backend = PythonLambdaSupport(fn, name: name)
        
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (Int) -> Bool) {
        let name = "lmb\(Self.lambdaUniqueName())"
            
        self.backend = PythonLambdaSupport(fn, name: name)
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (String) -> Bool) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        self.backend = PythonLambdaSupport(fn, name: name)
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (Double) -> Bool) {
        let name = "lmb\(Self.lambdaUniqueName())"

        self.backend = PythonLambdaSupport(fn, name: name)
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (Bool) -> Int) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { i in
            fn( i == 0 ? false : true)
        }
            
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (Bool) -> Bool) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { i in
            fn( i == 0 ? false : true)
        }
            
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (Bool) -> String) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { i in
            fn( i == 0 ? false : true)
        }
            
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (Bool) -> Double) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { i in
            fn( i == 0 ? false : true)
        }
            
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (PythonObject) -> Int) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { pop in
          //  fn(PythonObject(PyReference(pop)))
            fn(PythonObject(unsafe: pop))
        }
        
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }
    
    /// Use this to pass in a function as a PythonObject, say a numpy
    /// function like `np.sum`.  The function must have the shape `(A)->A`.
    public convenience init( fn: PythonObject ) {
        self.init( { f in fn(f) } )
    }
    
    public init( _ fn: @escaping (PythonObject) -> String) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { pop in
            fn(PythonObject(unsafe: pop))
        }
        
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (PythonObject) -> Double) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { pop in
            fn(PythonObject(unsafe: pop))
        }
        
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (PythonObject) -> Bool) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { pop in
            fn(PythonObject(unsafe: pop))
        }
        
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }

    public init( _ fn: @escaping (PythonObject) -> PythonObject) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { pop in
            fn(PythonObject(unsafe: pop)).asUnsafePointer
        }
        
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (PythonObject, PythonObject) -> PythonObject) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { popA, popB in
            fn(PythonObject(unsafe:popA),PythonObject( unsafe:popB )).asUnsafePointer
        }
        
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }

    public init( _ fn: @escaping (PythonObject, PythonObject, PythonObject) -> PythonObject) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { popA, popB, popC in
            fn(PythonObject(unsafe:popA),PythonObject( unsafe:popB ),PythonObject( unsafe:popC )).asUnsafePointer
        }
        
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(unsafe: self.backend.lambdaPointer )
    }
    
     private static func lambdaUniqueName() -> String {
        // force static library to be lazily instantiated
        guard Self.lib != nil else { fatalError("Python C library not instantiated!")}
        
        lambdaCounter += 1
         return "\(lambdaCounter)"
     }
    
    /// PythonLambda can't clean up memory properly thanks to the Swift/Python interface
    /// By default it leaks a small amount... 'dealloc' allows you to clean up "named" lambdas.
    /// For "unnamed" lambdas, you may wish to use With𝝺 { } { }   instead.
    public func dealloc() {
        self.backend.dealloc()
    }
}


extension PythonLambda : PythonConvertible {
    public var pythonObject: PythonObject {
        _ = Python // Ensure Python is initialized.
        return self.py
    }
}

/// Helper struct to encapsulate the deallocation of a lambda
private struct PythonLambdaApplication {
    let lambda: 𝝺
    let receiving: (𝝺) -> PythonObject
    
    public init(_ lambda:𝝺, to receiving: @escaping (𝝺) -> PythonObject) {
        self.lambda = lambda
        self.receiving = receiving
    }
    
    public func exec() -> PythonObject {
        let result = receiving(lambda)
        lambda.dealloc()
        return result
    }
}

infix operator >>>

/// Operator which scopes a lambda function to the closure which uses it, ensuring that the lambda is deallocated automatically.
///
/// - Example:
///
///       𝝺{ Int($0) } >>> { m in Python.map(m , [3.4, 2.4, 1.2] )  }
/// Will create a lambda function `{ Int($0) } `  and then apply it to the code in the the closure `{ m in Python.map(m , [3.4, 2.4, 1.2] )  }`.  Once the closure executes, the lambda will be deallocated.
/// - See Also: `withDeallocating` which is the same functionality but without the custom operator.
public func >>>(lambda:𝝺, receiving: @escaping (𝝺) -> PythonObject) -> PythonObject {
    return PythonLambdaApplication(lambda, to: receiving).exec()
}

/// Scopes a lambda function to the closure which uses it, ensuring that the lambda is deallocated automatically.
///
/// - Example
///
///          withDeallocating( PythonLambda{ Int($0) }, in: { m in Python.map(m , [3.4, 2.4, 1.2] )  } )
/// Will create a lambda function `{ Int($0) } `  and then apply it to the code in the the closure `{ m in Python.map(m , [3.4, 2.4, 1.2] )  }`.  Once the closure executes, the lambda will be deallocated.
/// - See Also: `>>>` which is the same functionality but with a  custom operator.
public func withDeallocating(_ lambda:PythonLambda, in receiving: @escaping (PythonLambda) -> PythonObject) -> PythonObject {
    return PythonLambdaApplication(lambda, to: receiving).exec()
}


extension PythonLambda {
    public static func execute(code: String, globals: [String:Any] , type: PythonLambdaSupport.PythonExecutionType = .Py_file_input, showErrors: Bool = false) -> PythonObject {
        guard Self.lib != nil else { fatalError("Python C library not instantiated!")}

        let pythonConvertibleGlobals = globals.filter { $0.value is PythonConvertible }.mapValues { ($0 as! PythonConvertible).pythonObject }
            
        let result = PythonLambdaSupport.executeCode(code: code, globals: pythonConvertibleGlobals.pythonObject.asUnsafePointer, type: type, showErrors: showErrors)
  //      print( PythonLambdaSupport.getGlobals() )
        return result.map {PythonObject(unsafe: $0 )} ?? Python.None
        
    }
    
    public static func addToGlobalDictionary<T: PythonConvertible>(key: String, value: T) {
        guard Self.lib != nil else { fatalError("Python C library not instantiated!")}

       PythonLambdaSupport.setInGlobalDictionary(key: key, value: value.pythonObject.asUnsafePointer)
    }
    
    public static func getFromGlobalDictionary(key: String) -> PythonObject {
        guard Self.lib != nil else { fatalError("Python C library not instantiated!")}

        let value = PythonLambdaSupport.getFromGlobalDictionary(key: key)
        return value.map { PythonObject(unsafe: $0) } ?? Python.None
    }
    

    /// Sets up redirection of stdout and stderr to a string. Call this prior to calling `Python.execute`. Call `retrieveRedirectedOutput()`
    /// afterwards to retrieve the redirected output.
    /// Errors are also picked up.
    ///
    /// You probably want to use `initializeInteractiveExecutor` and `executeInteractiveCode` instead.
    public static func setupRedirectionOfOutputToString() {
        let stdoutRedirect =
        """
        import sys
        class _CatchOutErr:
            def __init__(self):
                self.out = ''
                self.recent = ''
            def write(self, txt):
                self.recent += txt
            def mark(self):
                self.out += self.recent
                r = self.recent
                self.recent = ''
                return r
        _catchOutErr = _CatchOutErr()
        sys.stdout = _catchOutErr
        sys.stderr = _catchOutErr
        """
        
        Python.execute(stdoutRedirect)
    }
    
    /// Call this after calling `setupRedirectionOfOutputToString()` and executing some Python code, to retrieve recent changes to the standard output and error streams.
    /// Calling this function resets what is treated as "recent", so the next call of this function will
    /// retrieve any changes to stderr/stdout since the last call.
    public static func retrieveRecentRedirectedOutput() -> String {
        guard Self.lib != nil else { fatalError("Python C library not instantiated!")}

        let recent = String( PythonObject(unsafe: PythonLambdaSupport.retrieveRedirectedOutput(attrName: "_catchOutErr", valueName: "recent"))) ?? ""
        Python.execute("_catchOutErr.mark()")
        
        return recent
    }
    
    public static func retrieveAllRedirectedOutput() -> String {
        guard Self.lib != nil else { fatalError("Python C library not instantiated!")}

        return String( PythonObject(unsafe: PythonLambdaSupport.retrieveRedirectedOutput(attrName: "_catchOutErr", valueName: "out"))) ?? ""
    }
    
    
    private static func setupInteractiveEvaluation() {
        Python.execute(
        """
        class _InteractiveEval:
            def __init__(self):
                self._iv_value = None
                self._iv_toeval = ''
                self._iv_type = ''
            def _iveval(self):
                self._iv_value = eval(self._iv_toeval)
                self._iv_type = type(self._iv_value)
        _interactiveEval = _InteractiveEval()
        """
        )
    }
    
    private struct PythonInterpreterError : Error {}

    @available(OSX 10.15, *)
    public static func executeLikeInteractive_old(code: String) -> String {
        guard Self.lib != nil else { fatalError("Python C library not instantiated!")}

        func isDefiniteStatement(line: String) -> Bool {
            line.last.map { $0 == ":" } ?? true || line.first.map { $0.isWhitespace } ?? true
        }
        
        var result: String = ""
    

        do {
            var statementGroup : [String] = []
            for line in code.split(separator: "\n") {
                let sLine = String(line)
                if isDefiniteStatement(line: sLine) {
                    statementGroup += [sLine]
                } else {
                    if statementGroup.count > 0 {
                        Python.execute( statementGroup.joinedIfNecessary(with: "\n") )
                        statementGroup = []
                        
                        if PythonLambdaSupport.wasPythonErrorRaised() {
                            throw PythonInterpreterError()
                        }

                    }
                    
                    let tempResult = PythonLambda.retrieveRecentRedirectedOutput()
                    
                    if PythonLambdaSupport.canCompileCode(code: sLine, tagName: "Ace") {

                        let (expResultPtr, expTypePtr) = PythonLambdaSupport.executeAndReturn(code: sLine, attrName: "_interactiveEval", toEval: "_iv_toeval", evalExecute: "_iveval", valueName: "_iv_value", typeName: "_iv_type")
                        let expResult = expResultPtr.map { PythonObject(unsafe:$0) } ?? Python.None
                        let expType = expTypePtr.map { PythonObject(unsafe:$0) } ?? Python.None

                        let postEvalResult = PythonLambda.retrieveRecentRedirectedOutput()
                        if "\(expType)" == "<class 'NoneType'>" && postEvalResult == "" {
                            result = [result, tempResult]
                                .joinedIfNecessary(with: "\n")
                            Python.execute(sLine)
                        } else {
                            let elements =
                                [tempResult, "\("\(expType)" == "<class 'NoneType'>" ? "" : expResult)", postEvalResult]
                                .joinedIfNecessary(with: "\n")
                            result += elements
                        }
                    } else {
                        result += [tempResult]
                            .joinedIfNecessary(with: "\n")
                        
                        // reset error flag after failing to compile code
                        PythonLambdaSupport.clearPythonErrors()
                        Python.execute(sLine)
                    }
                                        
                    if PythonLambdaSupport.wasPythonErrorRaised() {
                        throw PythonInterpreterError()
                    }

                }
                
            }
            
            // Compute any leftover statement groups
            if statementGroup.count > 0 {
                Python.execute( statementGroup.joined(separator: "\n") )
                statementGroup = []
            }
        } catch {
            PythonLambdaSupport.showPythonErrors()
            PythonLambdaSupport.clearPythonErrors()
        }
        return result
    }

    @available(OSX 10.15, *)
    public static func executeLikeInteractive(code: String, writebacks: [String:String], magic: (String,String) -> (execute:String, result:String)) -> String {
        guard Self.lib != nil else { fatalError("Python C library not instantiated!")}

        var result: String = ""
    
        // execute everything except the last line, as a single block of code.
        // the last line might be an expression, so try that.
        
        func lineMayBeExpression(_ line: String) -> Bool {
            let hasLeadingWhitespace = line.starts(with: " ") || line.starts(with: "\t")
            guard !hasLeadingWhitespace else { return false }
            
            // can we compile it?
            let canCompile = PythonLambdaSupport.canCompileCode(code: line, tagName: "Ace")
            
            // reset if we got any errors while trying to compile
            PythonLambdaSupport.clearPythonErrors()
            return canCompile
        }
        
        func magicLine(_ line: Substring) -> (execute:String, result:String) {
            // magic lines always start with '%'
            // first word after '%' is the magic word, the rest is passed as a parameter
            if let first = line.first,
               first == "%" {
                let split = line.dropFirst().split(maxSplits: 1, whereSeparator: {$0 == " "}).map (String.init) + ["",""]
                return magic(split[0], split[1])
            }
            
            return (execute:String(line), result:"")
        }
        
        // "execute" won't return errors, we need to hunt for them...!
        func checkResultForError(_ result: String) -> Bool {
            return (result.contains("Traceback") && result.contains("Error:")) || (result.contains("SyntaxError: EOL while scanning"))
        }
        
        func checkWritebacks(result: PythonObject, ofType type: String) -> Bool {
            guard let writebackVariable = writebacks[type] else { return false }
            PythonLambda.addToGlobalDictionary(key: writebackVariable, value: result)
            return true
        }
        
        // Throw away any output received outside the interactive eval, and mark ready
        _ = PythonLambda.retrieveRecentRedirectedOutput()


        do {
            let statementLines = code.split(separator: "\n").map (magicLine)
            let magicResults = statementLines.map { $0.result }.joined(separator: "\n")
            let statementExecute = statementLines.map { $0.execute }
            let lastLine = statementExecute.last
            let evaluateLastLine: Bool
            let statementBlock: String
            
            result += magicResults
            
            if let lastLine = lastLine, lineMayBeExpression(lastLine) {
                statementBlock = statementExecute.dropLast().joined(separator: "\n")
                evaluateLastLine = true
            } else {
                statementBlock = statementExecute.joined(separator: "\n") // evaluate everything
                evaluateLastLine = false
            }
                    
            if statementBlock.count > 0 {
                Python.execute( statementBlock )
            }
            
            result += PythonLambda.retrieveRecentRedirectedOutput()
            
            if PythonLambdaSupport.wasPythonErrorRaised() || checkResultForError(result) {
                throw PythonInterpreterError()
            }
                                
                    
            // Try to evaulate last line and get the result.
            if let lastLine = lastLine, evaluateLastLine {

                    let (expResultPtr, expTypePtr) = PythonLambdaSupport.executeAndReturn(code: lastLine, attrName: "_interactiveEval", toEval: "_iv_toeval", evalExecute: "_iveval", valueName: "_iv_value", typeName: "_iv_type")
                    let expResult = expResultPtr.map { PythonObject(unsafe:$0) } ?? Python.None
                    let expType = "\(expTypePtr.map { PythonObject(unsafe:$0) } ?? Python.None)"

                    let postEvalResult = PythonLambda.retrieveRecentRedirectedOutput()
                    
                    // Couldn't evaluate
                    if expType == "<class 'NoneType'>" && postEvalResult == "" {
                        Python.execute(lastLine)
                    } else {
                        let elements =
                            ["\(expType == "<class 'NoneType'>" ? "" : expResult)", postEvalResult]
                            .joinedIfNecessary(with: "\n")
                        result += elements
                        
                        // check for writebacks
                        if checkWritebacks(result: expResult, ofType: expType) {
                            result += "\n(Automatically writing back '\(expType) result to '\(writebacks[expType]!)')"
                        }
                    }
            }
                                    
            if PythonLambdaSupport.wasPythonErrorRaised() || checkResultForError(result) {
                throw PythonInterpreterError()
            }

        } catch {
            PythonLambdaSupport.showPythonErrors()
            PythonLambdaSupport.clearPythonErrors()
        }
        return result
    }
    
    /// Call this once, before calling `executeInteractiveCode`.
    @available(OSX 10.15, *)
    public static func initializeInteractiveExecutor() {
        PythonLambda.setupRedirectionOfOutputToString()
        PythonLambda.setupInteractiveEvaluation()
    }
    
    /// Attempts to run a block of text in an interactive-REPL-like way. This is far from perfect as the code block is NOT
    /// being provided interactively; the interactive REPL disallows some things which should be fine in regular code.
    /// However two things 'executeInteractiveCode' attempts to do are: i) if the last line is an expression, return the
    /// result of the expression; ii) errors are returned via strings as per the Python interpreter.
    @available(OSX 10.15, *)
    public static func executeInteractiveCode(codeText: String, writebacks:[String:String] = [:], magic: (String,String) -> (execute:String,results:String) = {($1,"")}) -> String {

        let result = PythonLambda.executeLikeInteractive(code: codeText, writebacks: writebacks, magic: magic) 
    
        let output = PythonLambda.retrieveRecentRedirectedOutput()
        let refinedOutput: String
        if let last = output.last, last == "\n" {
            refinedOutput = String(output.dropLast())
        } else {
            refinedOutput = output
        }
        
        let refinedResult: String
        if result == "None" {
            refinedResult = ""
        } else {
            refinedResult = result
        }
        
        return [refinedResult, refinedOutput].joinedIfNecessary(with:  "\n")
    }
}
