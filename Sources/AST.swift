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
    
    /// ---------------
    /// pretty printing
    /// ---------------
    
    public static func pretty(_ value: BinaryOperator, supportsColor: Bool) -> String {
        return supportsColor ? Source.Color.green.apply(value.lexeme.description) : value.lexeme.description
    }
    
    public static func pretty(_ value: Bool, supportsColor: Bool) -> String {
        return supportsColor ? Source.Color.yellow.apply(value.description) : value.description
    }
    
    public static func pretty(_ value: Double, supportsColor: Bool) -> String {
        return supportsColor ? Source.Color.blue.apply(value.description) : value.description
    }
    
    public static func pretty(_ value: String, isIdentifier: Bool, supportsColor: Bool) -> String {
        let color = isIdentifier ? Source.Color.cyan : Source.Color.magenta
        let string = isIdentifier ? value : "\"" + value + "\""
        return supportsColor ? color.apply(string) : string
    }
    
    public static func pretty(_ value: Keyword, supportsColor: Bool) -> String {
        return supportsColor ? Source.Color.yellow.apply(value.rawValue) : value.rawValue
    }
    
    public static func pretty(_ primary: Primary, supportsColor: Bool) -> String {
        switch primary {
        case .boolean(let value):
            return pretty(value, supportsColor:supportsColor)
        case .function(let args, let body):
            var output = ""
            output += supportsColor ? Source.Color.green.apply("@") : "@"
            output += "("
            output += args.reduce("") {
                return $0.0 + pretty($0.1, isIdentifier:true, supportsColor:supportsColor) + ", "
            }
            if !args.isEmpty {
                let _ = output.unicodeScalars.popLast()
                let _ = output.unicodeScalars.popLast()
            }
            output += "){"
            output += body.reduce("") {
                return $0.0 + pretty($0.1, supportsColor:supportsColor) + ", "
            }
            if !body.isEmpty {
                let _ = output.unicodeScalars.popLast()
                let _ = output.unicodeScalars.popLast()
            }
            output += "}"
            return output
        case .identifier(let value):
            return pretty(value, isIdentifier:true, supportsColor:supportsColor)
        case .keyword(let value):
            return pretty(value, supportsColor:supportsColor)
        case .list(let values):
            var output = ""
            output += "["
            output += values.reduce("") {
                return $0.0 + pretty($0.1, supportsColor:supportsColor) + ", "
            }
            if !values.isEmpty {
                let _ = output.unicodeScalars.popLast()
                let _ = output.unicodeScalars.popLast()
            }
            output += "]"
            return output
        case .map(let values):
            var output = ""
            output += "{"
            output += values.reduce("") {
                let key = pretty($0.1.0, isIdentifier:true, supportsColor:supportsColor)
                let value = pretty($0.1.1, supportsColor:supportsColor)
                return $0.0 + key + ": " + value + ", "
            }
            if !values.isEmpty {
                let _ = output.unicodeScalars.popLast()
                let _ = output.unicodeScalars.popLast()
            }
            output += "}"
            return output
        case .number(let value):
            return pretty(value, supportsColor:supportsColor)
        case .string(let value):
            return pretty(value, isIdentifier:false, supportsColor:supportsColor)
        }
    }
    
    public static func pretty(_ expression: AST.Expression, supportsColor: Bool) -> String {
        switch expression {
        case .assign(let key, let value):
            var output = ""
            output += pretty(key, isIdentifier:true, supportsColor:supportsColor)
            output += ":"
            output += " "
            output += pretty(value, supportsColor:supportsColor)
            return output
        case .binary(let lhs, let op, let rhs):
            var output = ""
            output += "("
            output += pretty(lhs, supportsColor:supportsColor)
            output += " "
            output += pretty(op, supportsColor:supportsColor)
            output += " "
            output += pretty(rhs, supportsColor:supportsColor)
            output += ")"
            return output
        case .call(let lhs, let args):
            var output = ""
            output += pretty(lhs, supportsColor:supportsColor)
            output += "("
            output += args.reduce("") {
                let key = pretty($0.1.0, isIdentifier:true, supportsColor:supportsColor)
                let value = pretty($0.1.1, supportsColor:supportsColor)
                return $0.0 + key + ": " + value + ", "
            }
            if !args.isEmpty {
                let _ = output.unicodeScalars.popLast()
                let _ = output.unicodeScalars.popLast()
            }
            output += ")"
            return output
        case .get(let lhs, let index):
            var output = ""
            output += pretty(lhs, supportsColor:supportsColor)
            output += "["
            output += pretty(index, supportsColor:supportsColor)
            output += "]"
            return output
        case .primary(let primary):
            return pretty(primary, supportsColor:supportsColor)
        case .set(let lhs, let index, let rhs):
            var output = ""
            output += pretty(lhs, supportsColor:supportsColor)
            output += "["
            output += pretty(index, supportsColor:supportsColor)
            output += "]"
            output += ":"
            output += " "
            output += pretty(rhs, supportsColor:supportsColor)
            return output
        case .unary(let op, let rhs):
            var output = ""
            output += "("
            output += pretty(op, supportsColor:supportsColor)
            output += pretty(rhs, supportsColor:supportsColor)
            output += ")"
            return output

        }
    }

    public static func pretty(_ value: UnaryOperator, supportsColor: Bool) -> String {
        return supportsColor ? Source.Color.green.apply(value.lexeme.description) : value.lexeme.description
    }
}
