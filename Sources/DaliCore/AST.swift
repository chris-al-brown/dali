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
// AST.swift
// 10/20/2017
// Abstract syntax tree expressions and statements
// -----------------------------------------------------------------------------

import Foundation

public protocol ASTVisitor {
    associatedtype ASTExpressionValue
    associatedtype ASTStatementValue
    func visit(_ expression: ASTExpression) throws -> ASTExpressionValue
    func visit(_ statement: ASTStatement) throws -> ASTStatementValue
}

public enum ASTBinaryOperator: String {
    case add            = "+"
    case subtract       = "-"
    case multiply       = "*"
    case divide         = "/"
    
    case equalTo        = "="
    case lesserThan     = "<"
    case greaterThan    = ">"
    
    case and            = "&"
    case or             = "|"
    
    public init?(_ lexeme: TokenLexeme) {
        switch lexeme {
        case .plus:
            self = .add
        case .minus:
            self = .subtract
        case .star:
            self = .multiply
        case .slash:
            self = .divide
        case .equal:
            self = .equalTo
        case .carrotLeft:
            self = .lesserThan
        case .carrotRight:
            self = .greaterThan
        case .ampersand:
            self = .and
        case .bar:
            self = .or
        default:
            return nil
        }
    }
    
    public var lexeme: TokenLexeme {
        switch self {
        case .add:
            return .plus
        case .subtract:
            return .minus
        case .multiply:
            return .star
        case .divide:
            return .slash
        case .equalTo:
            return .equal
        case .lesserThan:
            return .carrotLeft
        case .greaterThan:
            return .carrotRight
        case .and:
            return .ampersand
        case .or:
            return .bar
        }
    }
    
    public var precedence: Int {
        switch self {
        case .and:
            return 10
        case .or:
            return 20
        case .equalTo:
            return 30
        case .lesserThan:
            return 40
        case .greaterThan:
            return 40
        case .add:
            return 50
        case .subtract:
            return 50
        case .multiply:
            return 60
        case .divide:
            return 60
        }
    }
}

public enum ASTDeclaration {
    case variable(TokenIdentifier, ASTExpression)
    case function(TokenIdentifier, [TokenIdentifier], [ASTStatement])
}

public struct ASTExpression: CustomStringConvertible {
    
    public init(_ type: ASTExpressionType, _ location: SourceLocation) {
        self.type = type
        self.location = location
    }
    
    public func accept<Visitor: ASTVisitor>(_ visitor: Visitor) throws -> Visitor.ASTExpressionValue {
        return try visitor.visit(self)
    }
    
    public var description: String {
        switch type {
        case .binary(let lhs, let op, let rhs):
            var output = ""
            output += "("
            output += lhs.description
            output += " "
            output += op.lexeme.description
            output += " "
            output += rhs.description
            output += ")"
            return output
        case .boolean(let value):
            return value.description
        case .call(let lhs, let args):
            var output = ""
            output += lhs.description
            output += "("
            output += args.reduce("") {
                let value = $1.description
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
            output += value.description
            return output
        case .string(let value):
            return "\"" + value + "\""
        case .unary(let op, let rhs):
            var output = ""
            output += "("
            output += op.lexeme.description
            output += rhs.description
            output += ")"
            return output
        }
    }
    
    public let type: ASTExpressionType
    public let location: SourceLocation
}

public indirect enum ASTExpressionType {
    
    /// 1 + 1
    case binary(ASTExpression, ASTBinaryOperator, ASTExpression)
    
    /// false
    case boolean(Bool)
    
    /// mix(#000000, #ffffff, 0.5)
    case call(ASTExpression, [ASTExpression])
    
    /// #ffffff
    case color(UInt32)
    
    /// x
    case getter(TokenIdentifier)
    
    /// var
    case keyword(TokenKeyword)
    
    /// 1.512
    case number(Double)
    
    /// name: "Chris"
    case setter(TokenIdentifier, ASTExpression)
    
    /// "message"
    case string(String)
    
    /// !true
    case unary(ASTUnaryOperator, ASTExpression)
}

public struct ASTStatement: CustomStringConvertible {
    
    public init(_ type: ASTStatementType, _ location: SourceLocation) {
        self.type = type
        self.location = location
    }
    
    public func accept<Visitor: ASTVisitor>(_ visitor: Visitor) throws -> Visitor.ASTStatementValue {
        return try visitor.visit(self)
    }
    
    public var description: String {
        switch type {
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
                    return $0 + $1.description + "\n"
                }
                if !args.isEmpty {
                    let _ = output.unicodeScalars.removeLast()
                    let _ = output.unicodeScalars.removeLast()
                }
                output += "\n}"
                return output
            case .variable(let name, let value):
                return "var \(name): \(value.description)"
            }
        case .expression(let expression):
            return expression.description
        case .return(let expression):
            return "return \(expression.description)"
        }
    }

    public let type: ASTStatementType
    public let location: SourceLocation
}

public enum ASTStatementType {
    case declaration(ASTDeclaration)
    case expression(ASTExpression)
    case `return`(ASTExpression)
}

public enum ASTUnaryOperator: String {
    case positive   = "+"
    case negative   = "-"
    case not        = "!"
    
    public init?(_ lexeme: TokenLexeme) {
        switch lexeme {
        case .plus:
            self = .positive
        case .minus:
            self = .negative
        case .exclamation:
            self = .not
        default:
            return nil
        }
    }
    
    public var lexeme: TokenLexeme {
        switch self {
        case .positive:
            return .plus
        case .negative:
            return .minus
        case .not:
            return .exclamation
        }
    }
}

