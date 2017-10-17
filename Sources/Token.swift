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
// Token.swift
// 01/20/2017
// Dali language tokens
// -----------------------------------------------------------------------------

import Foundation

public struct Token {
    
    public typealias Identifier = String

    public enum Keyword: String {
        case `func` = "func"
        case `var`  = "var"
        case print  = "print"
        
        public static func lexeme(for string: String) -> Lexeme? {
            switch string {
            case "func":
                return .keyword(.func)
            case "print":
                return .keyword(.print)
            case "var":
                return .keyword(.var)
            case "true":
                return .boolean(true)
            case "false":
                return .boolean(false)
            default:
                return nil
            }
        }
    }
    
    public enum Lexeme: Equatable {
        
        /// Single-character tokens
        case colon                  /// :
        case comma                  /// ,
        case curlyLeft              /// {
        case curlyRight             /// }
        case parenLeft              /// (
        case parenRight             /// )
        case semicolon              /// ;

        /// Single-character tokens (arithmetic)
        case plus                   /// +
        case minus                  /// -
        case star                   /// *
        case slash                  /// /
        
        /// Single-character tokens (comparison)
        case equal                  /// =
        case carrotLeft             /// <
        case carrotRight            /// >
        
        /// Single-character tokens (logical)
        case exclamation            /// !
        case ampersand              /// &
        case bar                    /// |
        
        /// Literals
        case boolean(Bool)          /// true or false
        case color(String)          /// #efefef
        case number(Double)         /// 1.512 or 15
        case string(String)         /// "This is a string"
        
        /// Identifier
        case identifier(Identifier) /// person
        
        /// Keywords
        case keyword(Keyword)       /// var, func
        
        /// End of file
        case end                    /// EOF
        
        public static func ==(lhs: Lexeme, rhs: Lexeme) -> Bool {
            switch (lhs, rhs) {
            case (.colon, .colon):
                return true
            case (.comma, .comma):
                return true
            case (.curlyLeft, .curlyLeft):
                return true
            case (.curlyRight, .curlyRight):
                return true
            case (.parenLeft, .parenLeft):
                return true
            case (.parenRight, .parenRight):
                return true
            case (.semicolon, .semicolon):
                return true
            case (.plus, .plus):
                return true
            case (.minus, .minus):
                return true
            case (.star, .star):
                return true
            case (.slash, .slash):
                return true
            case (.equal, .equal):
                return true
            case (.carrotLeft, .carrotLeft):
                return true
            case (.carrotRight, .carrotRight):
                return true
            case (.exclamation, .exclamation):
                return true
            case (.ampersand, .ampersand):
                return true
            case (.bar, .bar):
                return true
            case (.string(let lvalue), .string(let rvalue)):
                return lvalue == rvalue
            case (.number(let lvalue), .number(let rvalue)):
                return lvalue == rvalue
            case (.boolean(let lvalue), .boolean(let rvalue)):
                return lvalue == rvalue
            case (.color(let lvalue), .color(let rvalue)):
                return lvalue == rvalue
            case (.identifier(let lvalue), .identifier(let rvalue)):
                return lvalue == rvalue
            case (.keyword(let lvalue), .keyword(let rvalue)):
                return lvalue == rvalue
            case (.end, .end):
                return true
            default:
                return false
            }
        }
    }
    
    public init(_ lexeme: Lexeme, _ location: Source.Location) {
        self.lexeme = lexeme
        self.location = location
    }

    public let lexeme: Lexeme
    public let location: Source.Location
}

extension Token.Lexeme: CustomStringConvertible {

    public var description: String {
        switch self {
        case .colon:
            return ":"
        case .comma:
            return ","
        case .curlyLeft:
            return "{"
        case .curlyRight:
            return "}"
        case .parenLeft:
            return "("
        case .parenRight:
            return ")"
        case .semicolon:
            return ";"
        case .plus:
            return "+"
        case .minus:
            return "-"
        case .star:
            return "*"
        case .slash:
            return "/"
        case .equal:
            return "="
        case .carrotLeft:
            return "<"
        case .carrotRight:
            return ">"
        case .exclamation:
            return "!"
        case .ampersand:
            return "&"
        case .bar:
            return "|"
        case .string(let value):
            return "\"\(value)\""
        case .number(let value):
            return "\(value)"
        case .boolean(let value):
            return "\(value)"
        case .color(let value):
            return "#\(value.uppercased())"
        case .identifier(let value):
            return "\(value)"
        case .keyword(let value):
            return "\(value)"
        case .end:
            return "eof"
        }
    }
}
