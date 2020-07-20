# PythonLambda

# PythonLambda

This package works alongside the PythonKit package which adds Python support to Swift.  PythonLambda adds lambda support too, enabling Swift functions to be used directly as lambdas in Python in a type-safe fashion.  This is extremely useful in many real-world situations of using Swift with Python, eg mapping a lambda function over a Python list, or applying a function to a Pandas dataframe (my original motivation).

### Example
The Python code `map(lambda(x:x*2), [10,12,14] )`  could be written in Swift as:

```
import PythonKit
import PythonLambda

Python.map( PythonLambda {x in x*2} , [10,12,14] ) // [20,24,28]
```

As a convenience, and to improve the look of the code, the special character 𝝺 is provided as a typealias for `PythonLambda`. So the above can be written as:

```
Python.map( 𝝺{x in x*2} , [10,12,14] ) // [20,24,28]
````


A second example: sum all the rows in a Pandas dataframe:
```
let summer = 𝝺{(row:PythonObject) in Double(np.sum(row)) ?? 0}
let result = df.apply( summer, axis: 0 )
```

The lambda feature is quite comprehensive but does have some limitations, detailed below.

### Additional Features
The package also enables two additional features which can be useful when interfacing with Python code.

```
PythonStringLambda(lambda: String) -> PythonObject
```

will create a lambda directly from the Python code provided as a parameter. For example:

```
let doubler = PythonStringLambda(lambda: "x:x*2")  // x*2 is interpreted as Python code
df.apply( doubler.pythonObject )
```

For more complex use cases, it can be useful to run arbitrary Python code from Swift (eg, to define a function to be called in a lambda). The `Python` class is extended with `Python.execute` to allow this:

```
Python.execute("""
   def add5(i):
       return (i+5)
""")

let fiveAdder = PythonStringLambda(lambda: "i:add5(i)")
print( Python.list(Python.map( fiveAdder , [10,12,14] ) ) )
```

Note that this interface is inherently unsafe: errors or unexpected results may crash your Swift program with Python errors. In particular, the Python code passed in the string must be indented according to Python expectations.

### Limitations
Each of these limitations are documented in the PythonLambda interface documentation.  Here is some more detail.

1. PythonLambda only works on Python3 and above.

2. The PythonLambda interface only supports a limited number of mostly 1-parameter function shapes (specifically listed in the documentation). Generally as lambdas are simple functions, this is sufficient.  Two- and three-parameter "PythonObject" functions are also supported (which are essentially un-type-checked by Swift but can be used to pass more complex objects, see the Dataframe example above)

For more complex lambdas, `PythonStringLambda` can be used.


3. As Python doesn't really have the notion of an "escaping" function, a small memory leak is caused whenever a lambda is created. The lambda has to be created on the heap and kept around indefinitely, as neither Swift nor Python can "know" when the lambda is finished with. The lambda  must be _manually_ deallocated (if there is a concern about memory usage: the leak per lambda creation is only a few bytes).

Where you are concerned about memory leaks, however, eg for large numbers of lambda calls in a loop, there are two solutions:

- A. Create the lambda as a named variable before the loop; and then call `dealloc` on the variable afterwards. Eg:

```
let tripler = 𝝺{x in x*3}  // nb: creating 𝝺 causes a small leak
for _ in 1...1000 {   df.apply( tripler )  }
tripler.dealloc() // stop the leak 🚰
```

- B. Use the auto-deallocating function `withDeallocating`, or the equivalent custom operator `>>>`. This allows you to create and apply a lambda to a closure, and automatically deallocates it the lambda once the closure has executed. For example:

```
for _ in 1...1000 {
    𝝺{ Int($0) } >>> { m in Python.map(m , [3.4, 2.4, 1.2] )  }
}
```

or exactly equivalently, but without the custom operator and the 𝝺 character:

```
for _ in 1...1000 {
    withDeallocating( PythonLambda{ Int($0) }, in: { m in Python.map(m , [3.4, 2.4, 1.2] )  } )`
}
```

Lastly, note that lambda creation is _not_ thread-safe.  Each lambda is created with a unique identifier via a simple incrementing counter: if lambda creation happens on two threads simultaneously, the unique identifier creation may get confused.



### Notes
1. For further examples, see `PythonLambdaTests.swift`.
2. The code has only been tested on the Mac. 

