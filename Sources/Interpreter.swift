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
// Interpreter.swift
// 10/07/2017
// Dali language interpreter
// -----------------------------------------------------------------------------

import Foundation

public final class Interpreter: ASTVisitor {
    
    public init() {
        self.environment = Environment()
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
    
    public func interpret(_ statements: [ASTStatement]) throws -> [RuntimeObject?] {
        return try statements.map { try interpret($0) }
    }
    
    public func interpret(_ statement: ASTStatement) throws -> RuntimeObject? {
        return try visit(statement)
    }
    
    public func visit(_ expression: ASTExpression) throws -> RuntimeObject? {
        switch expression.type {
        case .binary(let lhs, let op, let rhs):
            guard let lvalue = try visit(lhs) else {
                throw InterpreterError.undefinedExpression(lhs.location)
            }
            guard let rvalue = try visit(rhs) else {
                throw InterpreterError.undefinedExpression(rhs.location)
            }
            guard let value = evaluate(lvalue, op, rvalue) else {
                throw InterpreterError.undefinedExpression(lhs.location)
            }
            return value
        case .boolean(let value):
            return BooleanObject(value)
        case .call(let callee, let arguments):
            guard let object = try visit(callee) else {
                throw InterpreterError.undefinedExpression(expression.location)
            }
            var values: [RuntimeObject] = []
            values.reserveCapacity(arguments.count)
            for argument in arguments {
                guard let value = try visit(argument) else {
                    throw InterpreterError.undefinedExpression(argument.location)
                }
                values.append(value)
            }
            guard let output = object.call(self, values) else {
                throw InterpreterError.objectIsNotCallable(callee.location)
            }
            return output
        case .color(let value):
            return ColorObject(value)
        case .getter(let name):
            guard let value = environment.get(name) else {
                throw InterpreterError.undefinedVariable(name, expression.location)
            }
            return value
        case .keyword(let name):
            throw InterpreterError.invalidKeywordUsage(name, expression.location)
        case .number(let value):
            return NumberObject(value)
        case .setter(let name, let expression):
            guard let value = try visit(expression) else {
                throw InterpreterError.undefinedExpression(expression.location)
            }
            environment.set(name, value)
            return nil
        case .string(let value):
            return StringObject(value)
        case .unary(let op, let rhs):
            guard let rvalue = try visit(rhs) else {
                throw InterpreterError.undefinedExpression(rhs.location)
            }
            guard let value = evaluate(op, rvalue) else {
                throw InterpreterError.undefinedExpression(rhs.location)
            }
            return value
        }
    }
    
    public func visit(_ statement: ASTStatement) throws -> RuntimeObject? {
        switch statement.type {
        case .declaration(let declaration):
            switch declaration {
            case .function(_, _, _):
                
                /// TODO: Create a function object here and define it in the scope
                return nil
                
            case .variable(let name, let expression):
                guard let value = try visit(expression) else {
                    throw InterpreterError.undefinedExpression(expression.location)
                }
                if !environment.define(name, value) {
                    throw InterpreterError.redefinedVariable(name, statement.location)
                }
            }
            return nil
        case .expression(let expression):
            return try visit(expression)
        }
    }

    private let environment: Environment
}

public enum InterpreterError: Swift.Error, CustomStringConvertible {
    case invalidKeywordUsage(TokenKeyword, SourceLocation)
    case redefinedVariable(TokenIdentifier, SourceLocation)
    case objectIsNotCallable(SourceLocation)
    case undefinedVariable(TokenIdentifier, SourceLocation)
    case undefinedExpression(SourceLocation)
    
    public var description: String {
        switch self {
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
