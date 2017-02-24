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
// 02/10/2017
// Abstract syntax tree for the language
// -----------------------------------------------------------------------------

import Foundation

public protocol ASTVisitor {
    associatedtype VisitedValue
    func visit(_ expression: AST.Expression) -> VisitedValue
}

public struct AST {

    public enum BinaryOperator {
        
        case add                /// +
        case subtract           /// -
        case multiply           /// *
        case divide             /// /
        
        case equalTo            /// =
        case lessThan           /// <
        case greaterThan        /// >
        
        case and                /// &
        case or                 /// |
        
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
    
    public indirect enum Expression {

        /// name: "Chris"
        case assign(Identifier, Expression)
        
        /// true & !true
        case binary(Expression, BinaryOperator, Expression)

        /// circle(x:0, y:0, radius:1)
        case call(Expression, [Identifier: Expression])

        /// geometry[circle]
        case get(Expression, Index)

        /// person[name]: "Nick" + " " + "Robins"
        case set(Expression, Index, Expression)

        /// true, my_var, "Hello", etc.
        case primary(Primary)

        /// !true
        case unary(UnaryOperator, Expression)
        
        public func accept<T: ASTVisitor>(_ visitor: T) -> T.VisitedValue {
            return visitor.visit(self)
        }
    }
    
    public typealias Identifier = String

    public typealias Index = Expression
    
    public enum Primary {
        
        /// false
        case boolean(Bool)

        /// { (first, second) | first + second }
        case function([Identifier], [Expression])

        /// x
        case identifier(Identifier)
        
        /// pi
        case keyword(Keyword)

        /// [x + 1, y + 1, z + 1]
        case list([Expression])
        
        /// [name: "Chris", age: 15]
        case map([Identifier: Expression])
        
        /// 1.512
        case number(Double)

        /// "message"
        case string(String)
    }
    
    public typealias Keyword = Token.Keyword
    
    public enum UnaryOperator {
        case positive           /// +
        case negative           /// -
        case not                /// !
        
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
}
