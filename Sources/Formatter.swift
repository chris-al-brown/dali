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
// Formatter.swift
// 10/17/2017
// Formatting of expressions, statements, and procedures for printing
// -----------------------------------------------------------------------------

import Foundation

public struct Formatter: ExpressionVisitor {
    
    public init() {}
    
    public func visit(_ expression: Expression) -> String {
        switch expression.symbol {
        case .binary(let lhs, let op, let rhs):
            var output = ""
            output += "("
            output += visit(lhs)
            output += " "
            output += op.lexeme.description
            output += " "
            output += visit(rhs)
            output += ")"
            return output
        case .boolean(let value):
            return value.description
        case .call(let lhs, let args):
            var output = ""
            output += visit(lhs)
            output += "("
            output += args.reduce("") {
                let value = visit($1)
                return $0 + value + ", "
            }
            if !args.isEmpty {
                let _ = output.unicodeScalars.removeLast()
                let _ = output.unicodeScalars.removeLast()
            }
            output += ")"
            return output
        case .color(let value):
            let r = (0xFF0000 & value) >> 16
            let g = (0x00FF00 & value) >> 8
            let b = (0x0000FF & value)
            let R = r.description
            let G = g.description
            let B = b.description
            return "#(\(R), \(G), \(B))"
        case .getter(let value):
            return value
        case .keyword(let value):
            return value.rawValue
        case .number(let value):
            return value.description
        case .setter(let key, let value):
            var output = ""
            output += key
            output += ":"
            output += " "
            output += visit(value)
            return output
        case .string(let value):
            return "\"" + value + "\""
        case .unary(let op, let rhs):
            var output = ""
            output += "("
            output += op.lexeme.description
            output += visit(rhs)
            output += ")"
            return output
        }
    }
}
