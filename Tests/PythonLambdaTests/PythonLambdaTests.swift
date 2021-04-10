//
//  PythonLambdaTests.swift
//
//

import XCTest
import PythonKit
import PythonLambda

class PythonLambdaTests: XCTestCase {
    let pmap = Python.map
    let plist = Python.list
    
    func testCheckVersion() {
        XCTAssertGreaterThanOrEqual(Python.versionInfo.major, 3)
        XCTAssertGreaterThanOrEqual(Python.versionInfo.minor, 7)
    }
    
    func testIntIntLambda() {
        let doubled = plist(pmap( 𝝺{x in x*2},  [-1, 20, 8] ))
        XCTAssertEqual(Array<Int>(doubled), [-2, 40, 16])
    }
    
    func testIntBoolLambda() {
        let triple = plist(pmap( 𝝺{(x:Int) in x.isMultiple(of: 3) ? true : false},  [45, 56, 63] ))
        XCTAssertEqual(Array<Bool>(triple) , [true, false, true])
    }
    
    func testIntStringLambda() {
        let strs = plist(pmap( 𝝺{(x:Int) in "\(x)"},  [-2,-3,100] ))
        XCTAssertEqual(Array<String>(strs), ["-2", "-3", "100"])
    }
    
    func testObjectStringLambda() {
        let strs = plist(pmap( 𝝺{(x:PythonObject) in "\(x)!!"},  PythonObject(["a", 2, true, 1.5] )))
        
        XCTAssertEqual(Array<String>(strs)!, ["a!!","2!!","True!!","1.5!!"])
    }
    
    func testBoolBoolLambda() {
        let bools = plist(pmap( 𝝺{x in !x},  [true, false, true] ))
        XCTAssertEqual(Array<Bool>(bools), [false, true, false])
    }
    
    func testObjectObjectLambda() {
        let objArray = plist(pmap( 𝝺{(x:PythonObject) in PythonObject([x])},  PythonObject(["a", 2, true, 1.5] )))
        XCTAssertEqual(["a"], objArray[0])
        XCTAssertEqual([2], objArray[1])
        XCTAssertEqual([true], objArray[2])
        XCTAssertEqual([1.5], objArray[3])
    }
    
    func testObjectObject_to_ObjectLambda() {
        let functools = Python.import("functools")
        let preduce = functools[dynamicMember: "reduce"]
        let nums = PythonObject([1,2,3,4,5])
        let reducer = 𝝺 { (x:PythonObject,y:PythonObject) -> PythonObject in PythonObject(Int(x)!+Int(y)!)  }
        
        let result = preduce( reducer, nums )
        
        XCTAssertEqual(15, Int(result)!)
    }
    
    func testLambdaDealloc() {
        let tripler = 𝝺{x in x*3}
        let tripled = plist(pmap( tripler,  [-1, 20, 8] ))
        tripler.dealloc()
        XCTAssertEqual(Array<Int>(tripled), [-3, 60, 24])

    }

    func testAutoDeallocatingLambdas() {
        var countRets = 0
        for _ in 1...10000 {
            // the count is to make sure the compiler doesn't try to cleverly optimize this away
            countRets += (𝝺{ Int($0) } >>> { l in self.plist(self.pmap(l , [3.4, 2.4, 1.2] ))  }).count
        }
        
        XCTAssertEqual(countRets, 30000)
    }
    
    func testLambdaName() {
        let tripler = 𝝺{x in x*3}
        
        XCTAssertTrue(Bool(Python.hasattr(tripler, "__name__") )!)
        
        let name = Python.getattr(tripler, "__name__")
        XCTAssertTrue(String(name)?.hasPrefix("lmb") ?? false)
    }
    
    func testStringLambda() {
        let len = PythonStringLambda(lambda: "x:len(x)")
        let results = plist(pmap( len, ["hello","bye",""]))
        XCTAssertEqual(results, [5, 3, 0])
    }
    
    func testExecuteAndStringLambda() {
        Python.execute("""
        def add5(i):
            return (i+5)
        """)

        let fiveAdder = PythonStringLambda(lambda: "i:add5(i)")
        let added = plist(pmap( fiveAdder , [10,12,14] ) )
        
        XCTAssertEqual(added, [15, 17, 19])
    }
    
    func testExecuteString() {
        let globals = ["dataframe": 1234]
        
        let code = """
            print(dataframe)
            print( globals() )
            """
        
        PythonLambda.addToGlobalDictionary(key:"dataframe", value: 1234)   // ok this now works, needs tidying up. 
        
        print( Python.execute(code) )
        
        Python.execute(
            """
            print(dataframe)
            a = 5827
            """
        )
        
        Python.execute(
            """
            print(a)
            """
        )

    }
    
    func testExecuteInteractive0() {
        let code1 =
        """
        print("Hi")
        """
        
        let output1 = executeInteractiveCode(codeText: code1)
        
        XCTAssertEqual(output1, "Hi\n")
    }
    
    func testExecuteInteractive1() {
        let code1 =
        """
        for i in [1,2,3,4]:
            print(i)
        print("Done")
        """
        
        let output1 = executeInteractiveCode(codeText: code1)
        
        XCTAssertEqual(output1, "1\n2\n3\n4\nDone\n")
    }
    
    func testExecuteInteractive2() {
        let code2 =
        """
        print("Done"
        """
        let output2 = executeInteractiveCode(codeText: code2)
        
        XCTAssertEqual(output2,
                        """
                          File "<string>", line 1
                            print("Done"
                                       ^
                        SyntaxError: unexpected EOF while parsing

                        """)
    }
    
    func testExecuteInteractive3() {
        let code3 =
        """
        a=1
        a+1
        """
        let output3 = executeInteractiveCode(codeText: code3)
        XCTAssertEqual(output3,"2\n")

        
    }
    
    func testExecuteInteractive4() {
        let code4 =
        """
        b='hello'
        b+' everyone'
        """
        let output4 = executeInteractiveCode(codeText: code4)
        XCTAssertEqual(output4,"hello everyone\n")
    }
    
    func testExecuteInteractive5() {
        let code5 =
        """
        for i in [1,2,3,4]:
            print(i)
        for v in ['a','b','c','d']:
            print(v)
        """
        let output5 = executeInteractiveCode(codeText: code5)
        XCTAssertEqual(output5,
                        """
                        1
                        2
                        3
                        4
                        a
                        b
                        c
                        d

                        """)
    }
    
    func testExecuteInteractive6() {
        let code6 =
        """
        print('hi')
        print('h
        print('lo')
        """
        let output6 = executeInteractiveCode(codeText: code6)
        XCTAssertEqual(output6,
                        """
                          File "<string>", line 2
                            print('h
                                   ^
                        SyntaxError: EOL while scanning string literal

                        """)
    }
    
    func testExecuteInteractive7() {
        let code7 =
        """
        a=1
        """
        let output7 = executeInteractiveCode(codeText: code7)
        XCTAssertEqual(output7,
                        """

                        """)
    }
    
    
    @available(OSX 10.15, *)
    private func executeInteractiveCode(codeText: String) -> String {
        PythonLambda.initializeInteractiveExecutor()
        
        return PythonLambda.executeInteractiveCode(codeText: codeText)
    }

}

