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
// Scanner.swift
// 01/20/2017
// Used to tokenize a source string
// -----------------------------------------------------------------------------

import Foundation

public final class Scanner {
    
    public enum Error: Swift.Error, CustomStringConvertible {
        case unexpectedCharacter(SourceLocation, UnicodeScalar)
        case unsupportedColorFormat(SourceLocation)
        case unsupportedNumericFormat(SourceLocation)
        case unterminatedString(SourceLocation)

        public var description: String {
            switch self {
            case .unexpectedCharacter(_, let character):
                return "Encountered an unsupported character: '\(character)'"
            case .unsupportedColorFormat(_):
                return "Colors are only supported in hexadecimal RGB format."
            case .unsupportedNumericFormat(_):
                return "Numbers are only supported in simple double and integer formats."
            case .unterminatedString(_):
                return "Strings require a closing double quote and cannot span multiple lines."
            }
        }

        public var location: SourceLocation {
            switch self {
            case .unexpectedCharacter(let location, _):
                return location
            case .unsupportedColorFormat(let location):
                return location
            case .unsupportedNumericFormat(let location):
                return location
            case .unterminatedString(let location):
                return location
            }
        }
    }

    public init(_ source: Source) {
        self.source = source
        self.tokens = []
        self.start = source.unicodeScalars.startIndex
        self.current = source.unicodeScalars.startIndex
    }
    
    public func advance() -> SourceScalar {
        let scalar = source.unicodeScalars[current]
        current = source.unicodeScalars.index(after:current)
        return scalar
    }
    
    private func append(lexeme: Token.Lexeme) {
        tokens.append(Token(lexeme, locate()))
    }

    private func isAlpha(_ scalar: SourceScalar) -> Bool {
        return CharacterSet.letters.contains(scalar) || scalar == "_"
    }
    
    private func isDigit(_ scalar: SourceScalar) -> Bool {
        return CharacterSet.decimalDigits.contains(scalar)
    }
    
    private func isHex(_ scalar: SourceScalar) -> Bool {
        return (isDigit(scalar) && scalar != ".")
            || scalar == "A" || scalar == "a"
            || scalar == "B" || scalar == "b"
            || scalar == "C" || scalar == "c"
            || scalar == "D" || scalar == "d"
            || scalar == "E" || scalar == "e"
            || scalar == "F" || scalar == "f"
    }
    
    private func locate() -> SourceLocation {
        return start..<current
    }
    
    private func peek() -> SourceScalar {
        if current >= source.unicodeScalars.endIndex {
            return SourceScalar("\0")
        }
        return source.unicodeScalars[current]
    }

    private func peekNext() -> SourceScalar {
        if source.unicodeScalars.index(after:current) >= source.unicodeScalars.endIndex {
            return SourceScalar("\0")
        }
        return source.unicodeScalars[source.unicodeScalars.index(after:current)]
    }
    
    private func reset() {
        tokens.removeAll(keepingCapacity:true)
        start = source.unicodeScalars.startIndex
        current = source.unicodeScalars.startIndex
    }
    
    public func scan() throws -> [Token] {
        /// Reset the scanner
        reset()
        /// Start the scanning
        while !isFinished {
            
            /// Advance to next character
            start = current
            let character = advance()
            switch character {
            
            /// Whitespace
            case " ", "\t", "\r", "\n":
                break
                
            /// Single-character tokens
            case ":":
                append(lexeme:.colon)
            case ",":
                append(lexeme:.comma)
            case "{":
                append(lexeme:.curlyLeft)
            case "}":
                append(lexeme:.curlyRight)
            case "(":
                append(lexeme:.parenLeft)
            case ")":
                append(lexeme:.parenRight)

            /// Single-character tokens (arithmetic)
            case "+":
                append(lexeme:.plus)
            case "-":
                append(lexeme:.minus)
            case "*":
                append(lexeme:.star)
            case "/":
                append(lexeme:.slash)

            /// Single-character tokens (comparison)
            case "=":
                append(lexeme:.equal)
            case "<":
                append(lexeme:.carrotLeft)
            case ">":
                append(lexeme:.carrotRight)

            /// Single-character tokens (logical)
            case "!":
                append(lexeme:.exclamation)
            case "&":
                append(lexeme:.ampersand)
            case "|":
                append(lexeme:.bar)

            /// Single-character tokens (comments)
            case "%":
                while peek() != "\n" && !isFinished {
                    let _ = advance()
                }
                break
            
            /// Literals (color)
            case "#":
                for _ in 0..<6 {
                    if isHex(peek()) {
                        let _ = advance()
                    } else {
                        throw Error.unsupportedColorFormat(locate())
                    }
                }
                let index = source.unicodeScalars.index(after:start)
                append(lexeme:.color(String(source.unicodeScalars[index..<current])))
                
            /// Literals (string)
            case "\"":
                while peek() != "\"" && !isFinished {
                    if peek() == "\n" {
                        throw Error.unterminatedString(locate())
                    }
                    let _ = advance()
                }
                if !isFinished {
                    // The closing "
                    let _ = advance()
                    // Trim the surrounding quotes
                    let lower = source.unicodeScalars.index(after:start)
                    let upper = source.unicodeScalars.index(before:current)
                    append(lexeme:.string(String(source.unicodeScalars[lower..<upper])))
                } else {
                    // Unterminated string error
                    throw Error.unterminatedString(locate())
                }
                
            /// Literals (number, boolean), identifiers and keywords
            default:
                /// Literals (number)
                if isDigit(character) {
                    /// Check for integer part
                    while isDigit(peek()) {
                        let _ = advance()
                    }
                    /// Check for decimal part
                    if peek() == "." {
                        if isDigit(peekNext()) {
                            /// Absorb the "."
                            let _ = advance()
                            /// Absorb the decimal part
                            while isDigit(peek()) {
                                let _ = advance()
                            }
                        } else {
                            /// Absorb the "."
                            let _ = advance()
                            /// And following stuff to get better error
                            while isAlpha(peek()) || isDigit(peek()) {
                                let _ = advance()
                            }
                            throw Error.unsupportedNumericFormat(locate())
                        }
                    }
                    
                    /// Attempt numeric conversion
                    if let value = Double(String(source.unicodeScalars[locate()])) {
                        append(lexeme:.number(value))
                    } else {
                        // Failed numeric conversion error
                        throw Error.unsupportedNumericFormat(locate())
                    }

                /// Literals (boolean), identifiers and keywords
                } else if isAlpha(character) {
                    while isAlpha(peek()) || isDigit(peek()) {
                        let _ = advance()
                    }
                    let value = String(String(source.unicodeScalars[locate()]))
                    if let keyword = Token.Keyword.lexeme(for:value) {
                        append(lexeme:keyword)
                    } else {
                        append(lexeme:.identifier(value))
                    }
                
                /// Failure
                } else {
                    // Unexpected character error
                    throw Error.unexpectedCharacter(locate(), character)
                }
            }
        }
        tokens.append(Token(.end, locate()))
        return tokens
    }
    
    private var isFinished: Bool {
        return current >= source.endIndex
    }
    
    private let source: Source
    private var tokens: [Token]
    private var start: SourceIndex
    private var current: SourceIndex
}





