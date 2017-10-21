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
// 10/21/2017
// Implementation of the runtime objects and functions
// -----------------------------------------------------------------------------

import Foundation

extension ASTBinaryOperator {
    
    public func evaluate(_ lhs: RuntimeObject, _ rhs: RuntimeObject) -> RuntimeObject? {
        switch self {
        case .add:
            if let left = lhs as? NumberObject, let right = rhs as? NumberObject {
                return left + right
            }
            if let left = lhs as? StringObject, let right = rhs as? StringObject {
                return left + right
            }
            return nil
        case .and:
            if let left = lhs as? BooleanObject, let right = rhs as? BooleanObject {
                return left && right
            }
            return nil
        case .divide:
            if let left = lhs as? NumberObject, let right = rhs as? NumberObject {
                return left / right
            }
            return nil
        case .equalTo:
            if let left = lhs as? BooleanObject, let right = rhs as? BooleanObject {
                return left == right
            }
            if let left = lhs as? ColorObject, let right = rhs as? ColorObject {
                return left == right
            }
            if let left = lhs as? NumberObject, let right = rhs as? NumberObject {
                return left == right
            }
            if let left = lhs as? StringObject, let right = rhs as? StringObject {
                return left == right
            }
            return nil
        case .greaterThan:
            if let left = lhs as? NumberObject, let right = rhs as? NumberObject {
                return left > right
            }
            return nil
        case .lesserThan:
            if let left = lhs as? NumberObject, let right = rhs as? NumberObject {
                return left < right
            }
            return nil
        case .multiply:
            if let left = lhs as? NumberObject, let right = rhs as? NumberObject {
                return left * right
            }
            return nil
        case .or:
            if let left = lhs as? BooleanObject, let right = rhs as? BooleanObject {
                return left || right
            }
            return nil
        case .subtract:
            if let left = lhs as? NumberObject, let right = rhs as? NumberObject {
                return left - right
            }
            return nil
        }
    }
}

extension ASTUnaryOperator {
    
    public func evaluate(_ rhs: RuntimeObject) -> RuntimeObject? {
        switch self {
        case .negative:
            if let right = rhs as? NumberObject {
                return -right
            }
            return nil
        case .not:
            if let right = rhs as? BooleanObject {
                return !right
            }
            return nil
        case .positive:
            if let right = rhs as? NumberObject {
                return +right
            }
            return nil
        }
    }
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
    
    public var description: String {
        return "<color \(value)>"
    }
    
    public let value: UInt32
}

public struct FunctionObject: RuntimeFunction {
    
    public init(_ name: String, _ arguments: [String], _ body: [ASTStatement], _ closure: RuntimeEnvironment) {
        self.name = name
        self.arguments = arguments
        self.body = body
        self.closure = closure
    }
    
    public func call(_ runtime: Runtime, _ values : [RuntimeObject]) -> RuntimeObject? {
        let environment = RuntimeEnvironment(closure)
        for (argument, value) in zip(self.arguments, values) {
            let _ = environment.define(argument, value)
        }
        do {
            try runtime.evaluate(body, in:environment)
        } catch let error as ReturnException {
            switch error {
            case .value(let rvalue):
                return rvalue
            }
        } catch let other {
            fatalError("FunctionObject call resulted in an unhandled error: " + other.localizedDescription)
        }
        return nil
    }
    
    public var description: String {
        var output = ""
        output += "\(name)("
        output += arguments.reduce("") {
            return $0 + $1 + ", "
        }
        if !arguments.isEmpty {
            let _ = output.unicodeScalars.removeLast()
            let _ = output.unicodeScalars.removeLast()
        }
        output += ")"
        return "<function \(output)>"
    }
    
    public var arity: Int? {
        return arguments.count
    }
    
    public let name: String
    public let arguments: [String]
    public let body: [ASTStatement]
    public let closure: RuntimeEnvironment
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
    
    public var description: String {
        return "<string \"\(value)\">"
    }
    
    public let value: String
}
