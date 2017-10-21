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

public final class Runtime: ASTVisitor {
    
    public init() {
        self.environment = RuntimeEnvironment(RuntimeEnvironment.globals)
    }
    
    private func evaluate(_ op: ASTUnaryOperator, _ lhs: RuntimeObject) -> RuntimeObject? {
        switch op {
        case .negative:
            if let left = lhs as? NumberObject {
                return -left
            }
            return nil
        case .not:
            if let left = lhs as? BooleanObject {
                return !left
            }
            return nil
        case .positive:
            if let left = lhs as? NumberObject {
                return +left
            }
            return nil
        }
    }
    
    private func evaluate(_ lhs: RuntimeObject, _ op: ASTBinaryOperator, _ rhs: RuntimeObject) -> RuntimeObject? {
        switch op {
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

    public func evaluate(_ statements: [ASTStatement], in environment: RuntimeEnvironment) throws {
        let current = self.environment
        self.environment = environment
        try statements.forEach { try evaluate($0) }
        self.environment = current
    }

    public func evaluate(_ statements: [ASTStatement]) throws {
        try statements.forEach { try evaluate($0) }
    }
    
    public func evaluate(_ statement: ASTStatement) throws {
        try visit(statement)
    }
    
    public func visit(_ expression: ASTExpression) throws -> RuntimeObject? {
        switch expression.type {
        case .binary(let lhs, let op, let rhs):
            guard let lvalue = try visit(lhs) else {
                throw RuntimeError.undefinedExpression(lhs.location)
            }
            guard let rvalue = try visit(rhs) else {
                throw RuntimeError.undefinedExpression(rhs.location)
            }
            guard let value = evaluate(lvalue, op, rvalue) else {
                throw RuntimeError.undefinedExpression(lhs.location)
            }
            return value
        case .boolean(let value):
            return BooleanObject(value)
        case .call(let callee, let arguments):
            guard let object = try visit(callee) else {
                throw RuntimeError.undefinedExpression(expression.location)
            }
            var values: [RuntimeObject] = []
            values.reserveCapacity(arguments.count)
            for argument in arguments {
                guard let value = try visit(argument) else {
                    throw RuntimeError.undefinedExpression(argument.location)
                }
                values.append(value)
            }
            guard let function = object as? RuntimeFunction else {
                throw RuntimeError.objectIsNotCallable(callee.location)
            }
            if let arity = function.arity, arity != values.count {
                throw RuntimeError.functionArityMismatch(callee.location)
            }
            let output = function.call(self, values)
            return output
        case .color(let value):
            return ColorObject(value)
        case .getter(let name):
            guard let value = environment.get(name) else {
                throw RuntimeError.undefinedVariable(name, expression.location)
            }
            return value
        case .keyword(let name):
            throw RuntimeError.invalidKeywordUsage(name, expression.location)
        case .number(let value):
            return NumberObject(value)
        case .setter(let name, let expression):
            guard let value = try visit(expression) else {
                throw RuntimeError.undefinedExpression(expression.location)
            }
            environment.set(name, value)
            return nil
        case .string(let value):
            return StringObject(value)
        case .unary(let op, let rhs):
            guard let rvalue = try visit(rhs) else {
                throw RuntimeError.undefinedExpression(rhs.location)
            }
            guard let value = evaluate(op, rvalue) else {
                throw RuntimeError.undefinedExpression(rhs.location)
            }
            return value
        }
    }
    
    public func visit(_ statement: ASTStatement) throws {
        switch statement.type {
        case .declaration(let declaration):
            switch declaration {
            case .function(let name, let arguments, let body):
                let function = FunctionObject(name, arguments, body, environment)
                if !environment.define(name, function) {
                     throw RuntimeError.redefinedVariable(name, statement.location)
                }
            case .variable(let name, let expression):
                guard let value = try visit(expression) else {
                    throw RuntimeError.undefinedExpression(expression.location)
                }
                if !environment.define(name, value) {
                    throw RuntimeError.redefinedVariable(name, statement.location)
                }
            }
        case .expression(let expression):
            let _ = try visit(expression)
        }
    }
    
    private var environment: RuntimeEnvironment
}

public final class RuntimeEnvironment {
    
    public static var globals: RuntimeEnvironment {
        let env = RuntimeEnvironment()
        let _ = env.define("exit", NativeExitFunction())
        let _ = env.define("print", NativePrintFunction())
        return env
    }
    
    public init() {
        self.parent = nil
        self.values = [:]
    }
    
    public init(_ parent: RuntimeEnvironment) {
        self.parent = parent
        self.values = [:]
    }
    
    public func define(_ name: TokenIdentifier, _ value: RuntimeObject) -> Bool {
        if values[name] == nil {
            set(name, value)
            return true
        }
        return false
    }
    
    public func get(_ name: TokenIdentifier) -> RuntimeObject? {
        if let value = values[name] {
            return value
        } else {
            return parent?.get(name)
        }
    }
    
    public func set(_ name: TokenIdentifier, _ value: RuntimeObject) {
        values[name] = value
    }
    
    private let parent: RuntimeEnvironment?
    private var values: [TokenIdentifier: RuntimeObject]
}

public enum RuntimeError: Swift.Error, CustomStringConvertible {
    case functionArityMismatch(SourceLocation)
    case invalidKeywordUsage(TokenKeyword, SourceLocation)
    case redefinedVariable(TokenIdentifier, SourceLocation)
    case objectIsNotCallable(SourceLocation)
    case undefinedVariable(TokenIdentifier, SourceLocation)
    case undefinedExpression(SourceLocation)
    
    public var description: String {
        switch self {
        case .functionArityMismatch(_):
            return "Function received the wrong number of arguments."
        case .invalidKeywordUsage(let keyword, _):
            return "Reserved keyword '\(keyword)' cannot be used in an expression."
        case .redefinedVariable(let name, _):
            return "Variable '\(name)' has already been defined in this scope."
        case .objectIsNotCallable(_):
            return "Object is not a callable function."
        case .undefinedVariable(let name, _):
            return "Variable '\(name)' is undefined in this scope."
        case .undefinedExpression(_):
            return "Expression is undefined."
        }
    }
    
    public var location: SourceLocation {
        switch self {
        case .functionArityMismatch(let location):
            return location
        case .invalidKeywordUsage(_, let location):
            return location
        case .redefinedVariable(_, let location):
            return location
        case .objectIsNotCallable(let location):
            return location
        case .undefinedVariable(_, let location):
            return location
        case .undefinedExpression(let location):
            return location
        }
    }
}

public protocol RuntimeObject: CustomStringConvertible {}

public protocol RuntimeFunction: RuntimeObject {
    func call(_ runtime: Runtime, _ arguments: [RuntimeObject]) -> RuntimeObject?
    var arity: Int? { get }
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
            // TODO: Needs a return statement or else nothing is ever returned
            try runtime.evaluate(body, in:environment)
        } catch let error {
            fatalError("FunctionObject call resulted in an unhandled error: " + error.localizedDescription)
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

