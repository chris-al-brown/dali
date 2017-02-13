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

/// AST (see EBNF grammer in Parser.swift)
public struct AST {

    public enum BinaryOperator {
        
        case assign             /// :
        
        /// Note: This works great except call requires a list of expressions
        
        /// case get            /// [ ]
        /// case set            /// :
        /// case call           /// ( )
        
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
            case .colon:
                self = .assign
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
            case .assign:
                return .colon
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
            case .assign:
                return 1
            case .and:
                return 2
            case .or:
                return 2
            case .equalTo:
                return 4
            case .lessThan:
                return 8
            case .greaterThan:
                return 8
            case .add:
                return 16
            case .subtract:
                return 16
            case .multiply:
                return 32
            case .divide:
                return 32
            }
        }
    }
    
    public indirect enum Expression {
        
        /// person[name]
        case access(Identifier, Expression)

        /// circle(x, y, radius)
        case call(Identifier, [Expression])
        
        /// name: "Chris"
        /// 1 + 1
        case binary(Expression, BinaryOperator, Expression)
        
        /// !true
        /// +index
        case unary(UnaryOperator, Expression)
        
        /// false
        case boolean(Bool)
        
        /// 1.512
        case number(Double)
        
        /// "message"
        case string(String)

        /// my_variable
        case identifier(Identifier)
    }

    public typealias Identifier = String

    public typealias Statement = Expression
    
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

        public var precedence: Int {
            switch self {
            case .positive:
                return 64
            case .negative:
                return 64
            case .not:
                return 64
            }
        }
    }
}

///// Function definition
//public struct Function {
//    
//    /// Function prototype
//    public struct Prototype {
//        
//        public let name: String
//        public let args: [String]
//    }
//    
//    public let prototype: Prototype
//    public let body: Expression
//}
