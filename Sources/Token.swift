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
    case comma                  /// ,
    case dot                    /// .
    case braceLeft              /// [
    case braceRight             /// ]
    case parenLeft              /// (
    case parenRight             /// )
    
    /// Single-character tokens (arithmetic)
    case plus                   /// +
    case minus                  /// -
    case star                   /// *
    case slash                  /// /

    /// Single-character tokens (comparison)
    case equal                  /// =
    case lessThan               /// <
    case greaterThan            /// >

    /// Single-character tokens (logical)
    case exclamation            /// !
    case ampersand              /// &
    case verticalBar            /// |

    /// Single-character tokens (comments)
    case hash                   /// # This is a comment
    
    /// Literals
    case string(String)         /// "This is a string"
    case number(Double)         /// 1.512 or 15
    case boolean(Bool)          /// true or false
    
    /// Identifier
    case identifier(String)     /// my_variable
    
    /// Keywords
    case none                   /// none
    case print                  /// print
    
    /// End of source
    case end                    /// end
    
    public static var keywords: [String: TokenType] = [
        "true": .boolean(true),
        "false": .boolean(false),
        "none": .none,
        "print": .print
    ]
    
    public var description: String {
        switch self {
        case .colon:
            return "colon"
        case .comma:
            return "comma"
        case .dot:
            return "dot"
        case .braceLeft:
            return "braceLeft"
        case .braceRight:
            return "braceRight"
        case .parenLeft:
            return "parenLeft"
        case .parenRight:
            return "parenRight"
        case .plus:
            return "plus"
        case .minus:
            return "minus"
        case .star:
            return "star"
        case .slash:
            return "slash"
        case .equal:
            return "equal"
        case .lessThan:
            return "lessThan"
        case .greaterThan:
            return "greaterThan"
        case .exclamation:
            return "exclamation"
        case .ampersand:
            return "ampersand"
        case .verticalBar:
            return "verticalBar"
        case .hash:
            return "hash"
        case .string(_):
            return "string"
        case .number(_):
            return "number"
        case .boolean(_):
            return "boolean"
        case .identifier(_):
            return "identifier"
        case .none:
            return "none"
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
