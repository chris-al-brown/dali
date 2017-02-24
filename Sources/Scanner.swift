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
        case unexpectedCharacter(Source.Location, UnicodeScalar)
        case unsupportedNumericFormat(Source.Location)
        case unterminatedString(Source.Location)

        public var description: String {
            switch self {
            case .unexpectedCharacter(_, let character):
                return "SyntaxError: Encountered an unsupported character: '\(character)'"
            case .unsupportedNumericFormat(_):
                return "SyntaxError: Numbers are only supported in simple double and integer formats."
            case .unterminatedString(_):
                return "SyntaxError: Strings require a closing double quote and cannot span multiple lines."
            }
        }

        public var location: Source.Location {
            switch self {
            case .unexpectedCharacter(let location, _):
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
        self.start = source.startIndex
        self.current = source.startIndex
    }
    
    public func advance() -> Source.Scalar {
        let scalar = source[current]
        current = source.index(after:current)
        return scalar
    }
    
    private func append(lexeme: Token.Lexeme) {
        tokens.append(Token(lexeme, locate()))
    }

    private func isAlpha(_ scalar: Source.Scalar) -> Bool {
        return CharacterSet.letters.contains(scalar) || scalar == "_"
    }
    
    private func isDigit(_ scalar: Source.Scalar) -> Bool {
        return CharacterSet.decimalDigits.contains(scalar)
    }
    
    private func locate() -> Source.Location {
        return start..<current
    }
    
    private func peek() -> Source.Scalar {
        if current >= source.endIndex {
            return Source.Scalar("\0")
        }
        return source[current]
    }

    private func peekNext() -> Source.Scalar {
        if source.index(after:current) >= source.endIndex {
            return Source.Scalar("\0")
        }
        return source[source.index(after:current)]
    }
    
    private func reset() {
        tokens.removeAll(keepingCapacity:true)
        start = source.startIndex
        current = source.startIndex
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
            case " ", "\t", "\r":
                break
            
            /// Newline
            case "\n":
                append(lexeme:.newline)
                
            /// Single-character tokens
            case "@":
                append(lexeme:.at)
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
            case "[":
                append(lexeme:.squareLeft)
            case "]":
                append(lexeme:.squareRight)

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
            case "#":
                while peek() != "\n" && !isFinished {
                    let _ = advance()
                }
                let index = source.index(after:start)
                append(lexeme:.hash(source.extract(index..<current)))
                
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
                    let lower = source.index(after:start)
                    let upper = source.index(before:current)
                    append(lexeme:.string(source.extract(lower..<upper)))
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
                    if let value = Double(String(source.extract(locate()))) {
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
                    /// Not exactly sure why this is optional?
                    let value = String(source.extract(locate())).unsafelyUnwrapped
                    if let keyword = Token.Keyword.getLexeme(for:value) {
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
    private var start: Source.Index
    private var current: Source.Index
}





