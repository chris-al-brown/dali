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
// Statement.swift
// 10/13/2017
// Like expressions but better
// -----------------------------------------------------------------------------

import Foundation

public protocol StatementVisitor {
    associatedtype StatementValue
    func visit(_ statement: Statement) throws -> StatementValue
}

public struct Statement {

    public enum Declaration {
        case variable(Token.Identifier, Expression)
        case function(Token.Identifier, [Token.Identifier], [Statement])
    }

    public enum Symbol {
        case declaration(Declaration)
        case expression(Expression)
    }
    
    public init(_ symbol: Symbol, _ location: SourceLocation) {
        self.symbol = symbol
        self.location = location
    }
    
    public func accept<Visitor: StatementVisitor>(_ visitor: Visitor) throws -> Visitor.StatementValue {
        return try visitor.visit(self)
    }
    
    public let symbol: Symbol
    public let location: SourceLocation
}

extension Statement: CustomStringConvertible {
    
    public var description: String {
        switch symbol {
        case .declaration(let declaration):
            switch declaration {
            case .function(let name, let args, let statement):
                var output = "func \(name): ("
                output += args.reduce("") {
                    return $0 + $1 + ", "
                }
                if !args.isEmpty {
                    let _ = output.unicodeScalars.removeLast()
                    let _ = output.unicodeScalars.removeLast()
                }
                output += ") {\n"
                output += statement.reduce("") {
                    return $0 + $1.description + ";\n"
                }
                if !args.isEmpty {
                    let _ = output.unicodeScalars.removeLast()
                    let _ = output.unicodeScalars.removeLast()
                }
                output += "}"
                return output
            case .variable(let name, let value):
                return "var \(name): \(value.description);"
            }
        case .expression(let expression):
            return expression.description
        }
    }
}
