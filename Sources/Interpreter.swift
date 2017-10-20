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

public final class Interpreter {
    
    public enum Error: Swift.Error, CustomStringConvertible {
        case invalidKeywordUsage(Token.Keyword, Source.Location)
        case redefinedVariable(Token.Identifier, Source.Location)
        case objectIsNotCallable(Source.Location)
        case undefinedVariable(Token.Identifier, Source.Location)
        case undefinedExpression(Source.Location)
        
        public var description: String {
            switch self {
            case .invalidKeywordUsage(let keyword, _):
                return "RuntimeError: Reserved keyword '\(keyword)' cannot be used in an expression."
            case .redefinedVariable(let name, _):
                return "RuntimeError: Variable '\(name)' has already been defined in this scope."
            case .objectIsNotCallable(_):
                return "RuntimeError: Object is not a callable function."
            case .undefinedVariable(let name, _):
                return "RuntimeError: Variable '\(name)' is undefined in this scope."
            case .undefinedExpression(_):
                return "RuntimeError: Expression is undefined."
            }
        }

        public var location: Source.Location {
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
    
    public init() {
        self.environment = Environment()
        self.globals = Environment.globals
    }
    
    public func interpret(_ statements: [Statement]) throws -> [Object?] {
        return try statements.map { try interpret($0) }
    }
    
    public func interpret(_ statement: Statement) throws -> Object? {
        return try visit(statement)
    }

    private let environment: Environment
    private let globals: Environment
}

extension Interpreter: ExpressionVisitor {
    
    public func visit(_ expression: Expression) throws -> Object? {
        switch expression.symbol {
        case .binary(let lhs, let op, let rhs):
            guard let lvalue = try visit(lhs) else {
                throw Error.undefinedExpression(lhs.location)
            }
            guard let rvalue = try visit(rhs) else {
                throw Error.undefinedExpression(rhs.location)
            }
            switch op {
            case .add:
                guard let object = (lvalue + rvalue) else {
                    throw Error.undefinedExpression(expression.location)
                }
                return object
            case .and:
                guard let object = (lvalue && rvalue) else {
                    throw Error.undefinedExpression(expression.location)
                }
                return object
            case .divide:
                guard let object = (lvalue / rvalue) else {
                    throw Error.undefinedExpression(expression.location)
                }
                return object
            case .equalTo:
                guard let object = (lvalue == rvalue) else {
                    throw Error.undefinedExpression(expression.location)
                }
                return object
            case .greaterThan:
                guard let object = (lvalue > rvalue) else {
                    throw Error.undefinedExpression(expression.location)
                }
                return object
            case .lessThan:
                guard let object = (lvalue < rvalue) else {
                    throw Error.undefinedExpression(expression.location)
                }
                return object
            case .multiply:
                guard let object = (lvalue * rvalue) else {
                    throw Error.undefinedExpression(expression.location)
                }
                return object
            case .or:
                guard let object = (lvalue || rvalue) else {
                    throw Error.undefinedExpression(expression.location)
                }
                return object
            case .subtract:
                guard let object = (lvalue - rvalue) else {
                    throw Error.undefinedExpression(expression.location)
                }
                return object
            }
        case .boolean(let value):
            return .boolean(value)
        case .call(let callee, let arguments):
            guard let object = try visit(callee) else {
                throw Error.undefinedExpression(expression.location)
            }
            var values: [Object] = []
            values.reserveCapacity(arguments.count)
            for argument in arguments {
                guard let value = try visit(argument) else {
                    throw Error.undefinedExpression(argument.location)
                }
                values.append(value)
            }
            guard let output = object.call(self, values) else {
                throw Error.objectIsNotCallable(callee.location)
            }
            return output
        case .color(let value):
            return .color(value)
        case .getter(let name):
            guard let value = environment.get(name) else {
                throw Error.undefinedVariable(name, expression.location)
            }
            return value
        case .keyword(let name):
            throw Error.invalidKeywordUsage(name, expression.location)
        case .number(let value):
            return .number(value)
        case .setter(let name, let expression):
            guard let value = try visit(expression) else {
                throw Error.undefinedExpression(expression.location)
            }
            environment.set(name, value)
            return nil
        case .string(let value):
            return .string(value)
        case .unary(let op, let rhs):
            guard let value = try visit(rhs) else {
                throw Error.undefinedExpression(rhs.location)
            }
            switch op {
            case .not:
                guard let object = !value else {
                    throw Error.undefinedExpression(expression.location)
                }
                return object
            case .negative:
                guard let object = -value else {
                    throw Error.undefinedExpression(expression.location)
                }
                return object
            case .positive:
                guard let object = +value else {
                    throw Error.undefinedExpression(expression.location)
                }
                return object
            }
        }
    }
}

extension Interpreter: StatementVisitor {

    public func visit(_ statement: Statement) throws -> Object? {
        switch statement.symbol {
        case .declaration(let declaration):
            switch declaration {
            case .function(_, _, _):
            
                /// TODO: Create a function object here and define it in the scope
                return nil
                
            case .variable(let name, let expression):
                guard let value = try visit(expression) else {
                    throw Error.undefinedExpression(expression.location)
                }
                if !environment.define(name, value) {
                    throw Error.redefinedVariable(name, statement.location)
                }
            }
            return nil
        case .expression(let expression):
            return try visit(expression)
        }
    }
}

