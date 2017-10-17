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
        case keywordUsage(Token.Keyword, Source.Location)
        case redefinedVariable(Token.Identifier, Source.Location)
        case undefinedVariable(Token.Identifier, Source.Location)
        case undefinedExpression(Source.Location)
        
        public var description: String {
            switch self {
            case .keywordUsage(let keyword, _):
                return "RuntimeError: Reserved keyword '\(keyword)' cannot be used in an expression."
            case .redefinedVariable(let name, _):
                return "RuntimeError: Variable '\(name)' has already been defined in this scope."
            case .undefinedVariable(let name, _):
                return "RuntimeError: Variable '\(name)' is undefined in this scope."
            case .undefinedExpression(_):
                return "RuntimeError: Expression is undefined."
            }
        }

        public var location: Source.Location {
            switch self {
            case .keywordUsage(_, let location):
                return location
            case .redefinedVariable(_, let location):
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
    }
    
    public func interpret(_ statements: [Statement]) throws {
        try statements.forEach { try visit($0) }
    }
    
    public func interpret(_ statement: Statement) throws {
        try visit(statement)
    }

    private let environment: Environment
}

extension Interpreter: ExpressionVisitor {
    
    public func visit(_ expression: Expression) throws -> AnyObject? {
        switch expression.symbol {
        case .binary(_, _, _):
            /// TODO: This will throw an undefined expression error
            return nil
        case .boolean(let value):
            return value as AnyObject?
        case .call(_, _):
            return nil
        case .color(let value):
            return value as AnyObject?
        case .getter(let name):
            do {
                return try environment.get(name)
            } catch _ {
                throw Error.undefinedVariable(name, expression.location)
            }
        case .keyword(let name):
            throw Error.keywordUsage(name, expression.location)
        case .number(let value):
            return value as AnyObject?
        case .setter(let name, let expression):
            if let value = try visit(expression) {
                environment.set(name, value)
                return nil
            } else {
                throw Error.undefinedExpression(expression.location)
            }
        case .string(let value):
            return value as AnyObject?
        case .unary(_, _):
            /// TODO: This will throw an undefined expression error
            return nil
        }
    }
}

extension Interpreter: StatementVisitor {
    
    public func visit(_ statement: Statement) throws {
        switch statement.symbol {
        case .declaration(let declaration):
            switch declaration {
            case .function(let name, let args, let body):
                print("function:", name, args, body)
            case .variable(let name, let expression):
                if let value = try visit(expression) {
                    do {
                        try environment.define(name, value)
                    } catch _ {
                        throw Error.redefinedVariable(name, statement.location)
                    }
                } else {
                    throw Error.undefinedExpression(statement.location)
                }
            }
        case .expression(let expression):
            let _ = try visit(expression)
        case .print(let expression):
            print("print:", expression)
        }
    }
}

