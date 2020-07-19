//
//  PythonCLibrary.swift
//  
//
//  Created by strictlyswift on 18-Jul-20.
//

import libpylamsupport
import PythonKit

/// Wrapper for the C library
public struct PythonCLibrary {
    public init() {
        let lib = PythonLibrary.sharedPythonLibrary
        initialisePythonLibrary(lib)
    }
}
