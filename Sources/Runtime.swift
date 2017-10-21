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
// RuntimeObject.swift
// 10/15/2017
// Basic runtime objects, environment, and interpreter
// -----------------------------------------------------------------------------

import Foundation

// TODO: FunctionObject
// --------------------
//    public func call(_ interpreter: Interpreter, _ arguments: [Object]) -> Object? {
//
//        /// TODO: Create a function object that can be evaluated
//        return nil
//
//    }
//}

public protocol RuntimeObject: CustomStringConvertible {
    func call(_ interpreter: Interpreter, _ arguments: [RuntimeObject]) -> RuntimeObject?
}

public struct BooleanObject: RuntimeObject {
    
    public static func ==(left: BooleanObject, right: BooleanObject) -> BooleanObject {
        return BooleanObject(left.value == right.value)
    }

    public static prefix func !(left: BooleanObject) -> BooleanObject {
        return BooleanObject(!left.value)
    }

    public static func &&(left: BooleanObject, right: BooleanObject) -> BooleanObject {
        return BooleanObject(left.value && right.value)
    }

    public static func ||(left: BooleanObject, right: BooleanObject) -> BooleanObject {
        return BooleanObject(left.value || right.value)
    }

    public init(_ value: Bool) {
        self.value = value
    }
    
    public func call(_ interpreter: Interpreter, _ arguments: [RuntimeObject]) -> RuntimeObject? {
        return nil
    }
    
    public var description: String {
        return "<boolean \(value)>"
    }

    public let value: Bool
}

public struct ColorObject: RuntimeObject {
    
    public static func ==(left: ColorObject, right: ColorObject) -> BooleanObject {
        return BooleanObject(left.value == right.value)
    }

    public init(_ value: UInt32) {
        self.value = value
    }
    
    public func call(_ interpreter: Interpreter, _ arguments: [RuntimeObject]) -> RuntimeObject? {
        return nil
    }
    
    public var description: String {
        return "<color \(value)>"
    }
    
    public let value: UInt32
}

public struct NumberObject: RuntimeObject {
    
    public static func ==(left: NumberObject, right: NumberObject) -> BooleanObject {
        return BooleanObject(left.value == right.value)
    }

    public static func +(left: NumberObject, right: NumberObject) -> NumberObject {
        return NumberObject(left.value + right.value)
    }
    
    public static func -(left: NumberObject, right: NumberObject) -> NumberObject {
        return NumberObject(left.value - right.value)
    }
    
    public static func *(left: NumberObject, right: NumberObject) -> NumberObject {
        return NumberObject(left.value * right.value)
    }
    
    public static func /(left: NumberObject, right: NumberObject) -> NumberObject {
        return NumberObject(left.value / right.value)
    }
    
    public static func <(left: NumberObject, right: NumberObject) -> BooleanObject {
        return BooleanObject(left.value < right.value)
    }
    
    public static func >(left: NumberObject, right: NumberObject) -> BooleanObject {
        return BooleanObject(left.value > right.value)
    }
    
    public static prefix func +(left: NumberObject) -> NumberObject {
        return NumberObject(+left.value)
    }

    public static prefix func -(left: NumberObject) -> NumberObject {
        return NumberObject(-left.value)
    }

    public init(_ value: Double) {
        self.value = value
    }
    
    public func call(_ interpreter: Interpreter, _ arguments: [RuntimeObject]) -> RuntimeObject? {
        return nil
    }
    
    public var description: String {
        return "<number \(value)>"
    }

    public let value: Double
}

public struct StringObject: RuntimeObject {
    
    public static func ==(left: StringObject, right: StringObject) -> BooleanObject {
        return BooleanObject(left.value == right.value)
    }
    
    public static func +(left: StringObject, right: StringObject) -> StringObject {
        return StringObject(left.value + right.value)
    }

    public init(_ value: String) {
        self.value = value
    }

    public func call(_ interpreter: Interpreter, _ arguments: [RuntimeObject]) -> RuntimeObject? {
        return nil
    }

    public var description: String {
        return "<string \"\(value)\">"
    }

    public let value: String
}

