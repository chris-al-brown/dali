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
// 01/31/2017
// Abstract syntax tree for the language
// -----------------------------------------------------------------------------

import Foundation

public struct AST {
    
    /// Expression in dali
    public indirect enum Expression {
        
        /// binary operator (expr1 bop expr2)
        case binary(Operator.Binary, Expression, Expression)
        
        /// boolean literal
        case boolean(Bool)
        
        /// function call (callee, args)
        case call(String, [Expression])
        
        /// number literal
        case number(Double)
        
        /// string literal
        case string(String)
        
        /// unary operator (uop expr)
        case unary(Operator.Unary, Expression)
        
        /// variable
        case variable(String)
    }
    
    /// Function definition
    public struct Function {
        
        /// Function prototype
        public struct Prototype {
            
            public let name: String
            public let args: [String]
        }
        
        public let prototype: Prototype
        public let body: Expression
    }
    
    /// Operators in dali
    public struct Operator {
        
        /// Available binary operators
        public enum Binary {
            
            /// Arithmetic operators
            case add                /// +
            case subtract           /// -
            case multiply           /// *
            case divide             /// /
            
            /// Comparison operators
            case equal              /// =
            case lessThan           /// <
            case greaterThan        /// >
            
            /// Logical operators
            case and                /// &
            case or                 /// |
            
            public var precedence: Int {
                return 0
            }
        }
        
        /// Available unary operators
        public enum Unary {
            
            /// Negative operator
            case negative           /// -
            
            /// Logical operator
            case not                /// !
            
            public var precedence: Int {
                return 0
            }
        }
    }
}
