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
// Validator.swift
// 02/23/2017
// Semantic validation for parsed AST.Expressions
// -----------------------------------------------------------------------------

import Foundation

public final class Validator: ExpressionVisitor {
    
    public enum Error: Swift.Error, CustomStringConvertible {
        case duplicateVariableDeclaration(Source.Location)
        
        public var description: String {
            switch self {
            case .duplicateVariableDeclaration(_):
                return "ScopeError: Variable is already declared in this scope."
            }
        }
        
        public var location: Source.Location {
            switch self {
            case .duplicateVariableDeclaration(let location):
                return location
            }
        }
    }
    
    public typealias Scope = Set<String>
    
    public init(_ expressions: [Expression]) {
        self.expressions = expressions
        self.scopes = []
        self.locals = [:]
    }
    
    private func define(_ variable: Token.Identifier, within expression: Expression) -> Error? {
        if let scope = scopes.last, scope.contains(variable) {
            return Error.duplicateVariableDeclaration(expression.location)
        }
        if var scope = scopes.popLast() {
            scope.insert(variable)
            scopes.append(scope)
        }
        return nil
    }
    
    private func lookup(_ variable: Token.Identifier, within expression: Expression) -> Error? {
        for (index, scope) in scopes.reversed().enumerated() {
            if scope.contains(variable) {
                locals[expression] = index
                return nil
            }
        }
        /// Global variable
        return nil
    }

    public func validate() throws -> [Expression] {
        for expression in expressions {
            if let error = expression.accept(self) {
                throw error
            }
        }
        return expressions
    }
    
    public func visit(_ expression: Expression) -> Error? {
        return resolve(expression)
    }
    
    private func resolve(_ expression: Expression) -> Error? {
        switch expression.symbol {
        case .assign(let variable, let rhs):
            return define(variable, within:expression) ?? resolve(rhs)
        case .binary(let lhs, _, let rhs):
            return resolve(lhs) ?? resolve(rhs)
        case .boolean(_):
            return nil
        case .call(let callee, let args):
            return resolve(callee) ?? args.flatMap { resolve($0.1) }.first
        case .function(let args, let body):
            scopes.append(Scope())
            let _args = args.flatMap { define($0, within:expression) }.first
            let _body = body.flatMap { resolve($0) }.first
            scopes.removeLast()
            return _args ?? _body
        case .get(let lhs, let index):
            return resolve(lhs) ?? resolve(index)
        case .keyword(_):
            return nil
        case .list(let values):
            return values.flatMap { resolve($0) }.first
        case .map(let values):
            return values.flatMap { resolve($0.1) }.first
        case .number(_):
            return nil
        case .set(let lhs, let index, let rhs):
            return resolve(lhs) ?? resolve(index) ?? resolve(rhs)
        case .string(_):
            return nil
        case .unary(_, let rhs):
            return resolve(rhs)
        case .variable(let variable):
            return lookup(variable, within:expression)
        }
    }
    
    private let expressions: [Expression]
    private var scopes: [Scope]
    private var locals: [Expression: Int]
}

