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
// Object.swift
// 10/15/2017
// Basic object types in dali
// -----------------------------------------------------------------------------

import Foundation

public enum Object {
    case boolean(Bool)
    case color(UInt32)
    case number(Double)
    case string(String)
    
    static prefix func !(left: Object) -> Object? {
        switch left {
        case .boolean(let value):
            return .boolean(!value)
        default:
            return nil
        }
    }

    static prefix func -(left: Object) -> Object? {
        switch left {
        case .number(let value):
            return .number(-value)
        default:
            return nil
        }
    }

    static prefix func +(left: Object) -> Object? {
        switch left {
        case .number(let value):
            return .number(+value)
        default:
            return nil
        }
    }
    
    static func +(left: Object, right: Object) -> Object? {
        switch (left, right) {
        case (.number(let lvalue), .number(let rvalue)):
            return .number(lvalue + rvalue)
        default:
            return nil
        }
    }

    static func -(left: Object, right: Object) -> Object? {
        switch (left, right) {
        case (.number(let lvalue), .number(let rvalue)):
            return .number(lvalue - rvalue)
        default:
            return nil
        }
    }

    static func *(left: Object, right: Object) -> Object? {
        switch (left, right) {
        case (.number(let lvalue), .number(let rvalue)):
            return .number(lvalue * rvalue)
        default:
            return nil
        }
    }

    static func /(left: Object, right: Object) -> Object? {
        switch (left, right) {
        case (.number(let lvalue), .number(let rvalue)):
            return .number(lvalue / rvalue)
        default:
            return nil
        }
    }
    
    static func ||(left: Object, right: Object) -> Object? {
        switch (left, right) {
        case (.boolean(let lvalue), .boolean(let rvalue)):
            return .boolean(lvalue || rvalue)
        default:
            return nil
        }
    }

    static func &&(left: Object, right: Object) -> Object? {
        switch (left, right) {
        case (.boolean(let lvalue), .boolean(let rvalue)):
            return .boolean(lvalue && rvalue)
        default:
            return nil
        }
    }

    static func ==(left: Object, right: Object) -> Object? {
        switch (left, right) {
        case (.boolean(let lvalue), .boolean(let rvalue)):
            return .boolean(lvalue == rvalue)
        case (.color(let lvalue), .color(let rvalue)):
            return .boolean(lvalue == rvalue)
        case (.number(let lvalue), .number(let rvalue)):
            return .boolean(lvalue == rvalue)
        case (.string(let lvalue), .string(let rvalue)):
            return .boolean(lvalue == rvalue)
        default:
            return nil
        }
    }
    
    static func <(left: Object, right: Object) -> Object? {
        switch (left, right) {
        case (.number(let lvalue), .number(let rvalue)):
            return .boolean(lvalue < rvalue)
        default:
            return nil
        }
    }

    static func >(left: Object, right: Object) -> Object? {
        switch (left, right) {
        case (.number(let lvalue), .number(let rvalue)):
            return .boolean(lvalue > rvalue)
        default:
            return nil
        }
    }
}

extension Object: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .boolean(let value):
            return "<boolean \(value)>"
        case .color(let value):
            return "<color #\(value)>"
        case .number(let value):
            return "<number \(value)>"
        case .string(let value):
            return "<string \"\(value)\">"
        }
    }
}
