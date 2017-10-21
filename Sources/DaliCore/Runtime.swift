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

public enum ReturnException: Swift.Error {
    case value(RuntimeObject)
}

public final class Runtime: ASTVisitor {
    
    public init() {
        self.environment = RuntimeEnvironment(RuntimeEnvironment.globals)
    }

    public func evaluate(_ statements: [ASTStatement], in current: RuntimeEnvironment) throws {
        let previous = environment
        self.environment = current
        try statements.forEach { try evaluate($0) }
        self.environment = previous
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
            guard let value = op.evaluate(lvalue, rvalue) else {
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
            guard let output = function.call(self, values) else {
                throw RuntimeError.invalidReturnStatement(callee.location)
            }
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
            guard let value = op.evaluate(rvalue) else {
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
        case .return(let expression):
            if let value = try visit(expression) {
                throw ReturnException.value(value)
            }
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
            values[name] = value
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
        if values[name] == nil {
            parent?.set(name, value)
        } else {
            values[name] = value
        }
    }
    
    private let parent: RuntimeEnvironment?
    private var values: [TokenIdentifier: RuntimeObject]
}

public enum RuntimeError: Swift.Error, CustomStringConvertible {
    case functionArityMismatch(SourceLocation)
    case invalidKeywordUsage(TokenKeyword, SourceLocation)
    case invalidReturnStatement(SourceLocation)
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
        case .invalidReturnStatement(_):
            return "All functions must include at least one return statement."
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
        case .invalidReturnStatement(let location):
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

public protocol RuntimeFunction: RuntimeObject {
    func call(_ runtime: Runtime, _ arguments: [RuntimeObject]) -> RuntimeObject?
    var arity: Int? { get }
}

public protocol RuntimeObject: CustomStringConvertible {}




