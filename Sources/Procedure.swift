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
// Procedure.swift
// 10/15/2017
// Procedures and Types
// -----------------------------------------------------------------------------

import Foundation

public enum Procedure {
    
    public enum Boolean {
        case constant(Bool)
        case function(() -> Bool)
    }
    
    case boolean(Boolean)
}


extension Procedure.Boolean {
    
    static prefix func !(left: Procedure.Boolean) -> Procedure.Boolean {
        switch left {
        case .constant(let value):
            return .constant(!value)
        case .function(let evaluate):
            return .function { !evaluate() }
        }
    }
    
    public func next() -> Bool {
        switch self {
        case .constant(let value):
            return value
        case .function(let evaluate):
            return evaluate()
        }
    }
}
