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
// Console.swift
// 02/13/2017
// Colored printing for seeing parsing
// -----------------------------------------------------------------------------

import Foundation

public struct Console {
    
    public enum Color: String {
        case black      = "\u{001B}[0;30m"
        case red        = "\u{001B}[0;31m"
        case green      = "\u{001B}[0;32m"
        case yellow     = "\u{001B}[0;33m"
        case blue       = "\u{001B}[0;34m"
        case magenta    = "\u{001B}[0;35m"
        case cyan       = "\u{001B}[0;36m"
        case white      = "\u{001B}[0;37m"

        public func apply(_ item: Any) -> String {
            return "\(prefix)\(item)\(suffix)"
        }
        
        public var prefix: String {
            return self.rawValue
        }
        
        public var suffix: String {
            return "\u{001B}[0;0m"
        }
    }
    
    public static func print(_ string: String, color: Color? = nil, separator: String = " ", terminator: String = "\n") {
        if let color = color {
            Swift.print(color.apply(string), separator:separator, terminator:terminator)
        } else {
            Swift.print(string, separator:separator, terminator:terminator)
        }
    }
    
    public static func print(_ tokens: [Token], colored: Bool = true) {
        if colored {
            for token in tokens {
                let lexeme = token.lexeme
                switch lexeme {
                /// Punctuation
                case .colon, .comma, .curlyLeft, .curlyRight, .parenLeft, .parenRight, .squareLeft, .squareRight:
                    Swift.print(lexeme, separator:"", terminator:" ")
                    
                /// Operators
                case .plus, .minus, .star, .slash, .equal, .carrotLeft, .carrotRight, .exclamation, .ampersand, .bar:
                    Swift.print(Color.white.apply(lexeme), separator:"", terminator:" ")
                    
                /// Hash
                case .hash:
                    Swift.print(Color.black.apply(lexeme), separator:"", terminator:" ")
                    
                /// Literals
                case .boolean(_):
                    Swift.print(Color.yellow.apply(lexeme), separator:"", terminator:" ")
                    
                case .number(_):
                    Swift.print(Color.blue.apply(lexeme), separator:"", terminator:" ")
                    
                case .string(_):
                    Swift.print(Color.magenta.apply(lexeme), separator:"", terminator:" ")
                    
                case .identifier(_):
                    Swift.print(Color.cyan.apply(lexeme), separator:"", terminator:" ")
                    
                    /// Keywords (green)
                    
                /// Newlines
                case .eol, .eos:
                    Swift.print(Color.black.apply(lexeme), separator:"", terminator:"\n")
                }
            }
        } else {
            for token in tokens {
                let lexeme = token.lexeme
                switch lexeme {
                case .eol, .eos:
                    Swift.print(lexeme, separator:"", terminator:"\n")
                default:
                    Swift.print(lexeme, separator:"", terminator:" ")
                }
            }

        }
    }
    
//    public static func format(_ lexeme: Token.Lexeme) -> String {
//        switch lexeme {
//        /// Punctuation
//        case .colon, .comma, .curlyLeft, .curlyRight, .parenLeft, .parenRight, .squareLeft, .squareRight:
//            Color.blue.format(lexeme.description)
//            
//            /// Operators
//            
//        /// Literals
//        case .boolean(let value):
//            let color = Color.yellow
//            Swift.print("\(color.prefix)\(token.lexeme)\(color.suffix)", separator:" ", terminator:"")
//        case .string(let value):
//            let color = Color.magenta
//            Swift.print("\(color.prefix)\(token.lexeme)\(color.suffix)", separator:" ", terminator:"")
//        case .identifier(let value):
//            let color = Color.magenta
//            Swift.print("\(color.prefix)\(token.lexeme)\(color.suffix)", separator:" ", terminator:"")
//            
//            
//        /// Newlines
//        case .eol, .eos:
//            Swift.print()
//        }
//    }
    
//    public static func print(_ tokens: [Token], verbose: Bool = false) {
//        for token in tokens {
//            print(token, verbose:verbose)
//        }
//    }

    
//    public static func format(_ tokens: [Token], verbose: Bool = false) -> String {
//        var output = ""
//        for token in tokens {
//            output += format(token, verbose:verbose)
//        }
//        return output
//    }
//
//    public static func format(_ lexeme: Token.Lexeme) -> String {
//        let color = Color.red
//        return "\(color.prefix)\(lexeme)\(color.suffix)"
//    }
//
//    public static func format(_ location: Token.Location) -> String {
//        let color = Color.black
//        return "\(color.prefix)\(location)\(color.suffix)"
//    }
}
