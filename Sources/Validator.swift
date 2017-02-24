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

public final class Validator: ASTVisitor {
    
    public enum Error: Swift.Error, CustomStringConvertible {
        case callingXXX
        case duplicateVariableDeclaration(String)
        
        public var description: String {
            switch self {
            case .callingXXX:
                return "Calling something that isn't callable."
            case .duplicateVariableDeclaration(let name):
                return "A variable named '\(name)' already exists in this scope."
            }
        }
    }
    
    public typealias Scope = [String: Bool]
    
    public init(_ expressions: [AST.Expression]) {
        self.expressions = expressions
        self.scopes = []
    }
    
    public func validate() throws -> [AST.Expression] {
        for expression in expressions {
            if let error = expression.accept(self) {
                throw error
            }
        }
        return expressions
    }
    
    public func visit(_ expression: AST.Expression) -> Error? {
        switch expression {
        case .assign(_, let rhs):
            return rhs.accept(self)
        case .binary(_, _, _):
            return nil
        case .call(let callee, let args):
            return validateCall(callee, args)
        case .get(_, _):
            return nil
        case .primary(let value):
            switch value {
            case .boolean(_):
                return nil
            case .function(_, _):
                return nil
            case .identifier(_):
                return nil
            case .keyword(_):
                return nil
            case .list(_):
                return nil
            case .map(_):
                return nil
            case .number(_):
                return nil
            case .string(_):
                return nil
            }
        case .set(_, _, _):
            return nil
        case .unary(_, _):
            return nil
        }
    }
    
    /// TODO: Not really correct
    private func validateCall(_ callee: AST.Expression, _ args: [AST.Identifier: AST.Expression]) -> Error? {
        switch callee {
        case .primary(_):
            return Error.callingXXX
        default:
            return nil
        }
    }
    
//    private func pushScope() {
//        scopes.append([:])
//    }
//    
//    private func popScope() -> Scope {
//        return scopes.removeLast()
//    }
//    
//    private var hasScope: Bool {
//        return !scopes.isEmpty
//    }
    
    private let expressions: [AST.Expression]
    private var scopes: [Scope]
}

