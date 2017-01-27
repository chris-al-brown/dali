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

public enum TokenType: CustomStringConvertible {
    
    /// Single-character tokens
    case colon                  /// :
    case parenLeft              /// (
    case parenRight             /// )
    
    /// Single-character tokens (arithmetic)
    case add                    /// +
    case subtract               /// -
    case multiply               /// *
    case divide                 /// /

    /// Single-character tokens (comparison)
    case equal                  /// =
    case lessThan               /// <
    case greaterThan            /// >

    /// Single-character tokens (logical)
    case not                    /// !
    case and                    /// &
    case or                     /// |

    /// Single-character tokens (comments)
    case comment                /// # This is a comment
    
    /// Literals
    case stringLiteral(String)  /// "This is a string"
    case numberLiteral(Double)  /// 1.512 or 15
    case booleanLiteral(Bool)   /// true or false
    
    /// Identifier
    case identifier(String)     /// my_variable
    
    /// Keywords
    case none                   /// none
    case boolean                /// boolean
    case number                 /// number
    case string                 /// string
    case print                  /// print
    
    /// End of source
    case end                    /// end
    
    public static var keywords: [String: TokenType] = [
        "true": .booleanLiteral(true),
        "false": .booleanLiteral(false),
        "none": .none,
        "boolean": .boolean,
        "number": .number,
        "string": .string,
        "print": .print
    ]
    
    public var description: String {
        switch self {
        case .colon:
            return "colon"
        case .parenLeft:
            return "parenLeft"
        case .parenRight:
            return "parenRight"
        case .add:
            return "add"
        case .subtract:
            return "subtract"
        case .multiply:
            return "multiply"
        case .divide:
            return "divide"
        case .equal:
            return "equal"
        case .lessThan:
            return "lessThan"
        case .greaterThan:
            return "greaterThan"
        case .not:
            return "not"
        case .and:
            return "and"
        case .or:
            return "or"
        case .comment:
            return "comment"
        case .stringLiteral(_):
            return "stringLiteral"
        case .numberLiteral(_):
            return "numberLiteral"
        case .booleanLiteral(_):
            return "booleanLiteral"
        case .identifier(_):
            return "identifier"
        case .none:
            return "none"
        case .boolean:
            return "boolean"
        case .number:
            return "number"
        case .string:
            return "string"
        case .print:
            return "print"
        case .end:
            return "end"
        }
    }
}

public struct Token: CustomStringConvertible {
    
    public init(type: TokenType, lexeme: String) {
        self.type = type
        self.lexeme = lexeme
    }
    
    public var description: String {
        switch type {
        case .end:
            return "Token(\(type))"
        default:
            return "Token(\(type), '\(lexeme)')"
        }
    }
    
    public let type: TokenType
    public let lexeme: String
}
