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
// Expression.swift
// 02/24/2017
// Abstract syntax tree expressions
// -----------------------------------------------------------------------------

import Foundation

public protocol ExpressionVisitor {
    associatedtype VisitedValue
    func visit(_ expression: Expression) -> VisitedValue
}

public struct Expression {
    
    public enum BinaryOperator: String {
        case add            = "+"
        case subtract       = "-"
        case multiply       = "*"
        case divide         = "/"
        
        case equalTo        = "="
        case lessThan       = "<"
        case greaterThan    = ">"
        
        case and            = "&"
        case or             = "|"
        
        public init?(_ lexeme: Token.Lexeme) {
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
                self = .lessThan
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
        
        public var lexeme: Token.Lexeme {
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
            case .lessThan:
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
            case .lessThan:
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
    
    public indirect enum Symbol {
        
        /// name: "Chris"
        case assign(Token.Identifier, Expression)
        
        /// 1 + 1
        case binary(Expression, BinaryOperator, Expression)
        
        /// false
        case boolean(Bool)
        
        /// mix(#000000, #ffffff, 0.5)
        case call(Expression, [Expression])

        /// #ffffff
        case color(UInt32)
        
        /// pi
        case keyword(Token.Keyword)
        
        /// 1.512
        case number(Double)

        /// "message"
        case string(String)
        
        /// !true
        case unary(UnaryOperator, Expression)

        /// x
        case variable(Token.Identifier)
    }
    
    public enum UnaryOperator: String {
        case positive   = "+"
        case negative   = "-"
        case not        = "!"
        
        public init?(_ lexeme: Token.Lexeme) {
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
        
        public var lexeme: Token.Lexeme {
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
    
    public init(_ symbol: Symbol, _ location: Source.Location) {
        self.symbol = symbol
        self.location = location
    }
    
    public func accept<Visitor: ExpressionVisitor>(_ visitor: Visitor) -> Visitor.VisitedValue {
        return visitor.visit(self)
    }

    public let symbol: Symbol
    public let location: Source.Location
}


