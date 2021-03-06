// -----------------------------------------------------------------------------
// Copyright (c) 2017, Christopher A. Brown (chris-al-brown)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// dali
// Stdlib.swift
// 10/21/2017
// Native implementations of runtime objects and functions
// -----------------------------------------------------------------------------

import Foundation

public struct NativeExitFunction: RuntimeFunction {
    
    public init() {}
    
    public func call(_ runtime: Runtime, _ arguments: [RuntimeObject]) -> RuntimeObject? {
        exit(EXIT_SUCCESS)
    }
    
    public var arity: Int? {
        return 0
    }
    
    public var description: String {
        return "<function exit()>"
    }
}

public struct NativePrintFunction: RuntimeFunction {
    
    public init() {}
    
    public func call(_ runtime: Runtime, _ arguments: [RuntimeObject]) -> RuntimeObject? {
        print(arguments)
        return self
    }
    
    public var arity: Int? {
        return nil
    }
    
    public var description: String {
        return "<function print(...)>"
    }
}
