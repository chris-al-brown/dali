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

public final class Interpreter: ExpressionVisitor, StatementVisitor {

    public enum Error: Swift.Error, CustomStringConvertible {
        case xxx(Source.Location)
        
        public var description: String {
            switch self {
            case .xxx(_):
                return "RuntimeError: xxx"
            }
        }
        
        public var location: Source.Location {
            switch self {
            case .xxx(let location):
                return location
            }
        }
    }
    
    public func interpret(_ expressions: [Expression]) -> [Double?] {
        return expressions.map { visit($0) }
    }
    
    public func interpret(_ expression: Expression) -> Double? {
        return visit(expression)
    }
    
    public func interpret(_ statements: [Statement]) throws {
        statements.forEach { visit($0) }
    }
    
    public func interpret(_ statement: Statement) throws {
        visit(statement)
    }

    public func visit(_ expression: Expression) -> Double? {
        switch expression.symbol {
        case .binary(let lhs, let op, let rhs):
            switch (visit(lhs), op, visit(rhs)) {
            case (.some(let lvalue), .add, .some(let rvalue)):
                return lvalue + rvalue
            case (.some(let lvalue), .subtract, .some(let rvalue)):
                return lvalue - rvalue
            case (.some(let lvalue), .multiply, .some(let rvalue)):
                return lvalue * rvalue
            case (.some(let lvalue), .divide, .some(let rvalue)):
                return lvalue / rvalue
            default:
                return nil
            }
        case .boolean(let value):
            return value ? 1.0 : 0.0
        case .call(_, _):
            return nil
        case .color(let value):
            return Double(value)
        case .getter(_):
            return nil
        case .keyword(_):
            return nil
        case .number(let value):
            return value
        case .setter(_, _):
            return nil
        case .string(let value):
            return Double(value)
        case .unary(let op, let rhs):
            switch (op, visit(rhs)) {
            case (.negative, .some(let value)):
                return -value
            case (.not, _):
                return nil
            case (.positive, .some(let value)):
                return +value
            default:
                return nil
            }
        }
    }
    
    public func visit(_ statement: Statement) {
        switch statement.symbol {
        case .declaration(let declaration):
            switch declaration {
            case .function(let name, let args, let body):
                print("function:", name, args, body)
            case .variable(let name, let value):
                print("variable:", name, value)
            }
        case .expression(let expression):
            print("expression:", expression)
        case .print(let expression):
            print("print:", expression)
        }
    }
}
