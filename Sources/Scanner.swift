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
    
    /// (Location, [Token], String)
    
    public enum Error: Swift.Error {
        case unexpectedCharacter(Location, [Token], String, UnicodeScalar)
        case unsupportedNumericFormat(Location, [Token], String)
        case unterminatedString(Location, [Token], String)
        
        public var location: Location {
            switch self {
            case .unexpectedCharacter(let location, _, _, _):
                return location
            case .unsupportedNumericFormat(let location, _, _):
                return location
            case .unterminatedString(let location, _, _):
                return location
            }
        }
        
        /// Partial tokens up until the error
        public var tokens: [Token] {
            switch self {
            case .unexpectedCharacter(_, let tokens, _, _):
                return tokens
            case .unsupportedNumericFormat(_, let tokens, _):
                return tokens
            case .unterminatedString(_, let tokens, _):
                return tokens
            }
        }
        
        /// Remainder of the line being parsed
        public var remainder: String {
            switch self {
            case .unexpectedCharacter(_, _, let remainder, _):
                return remainder
            case .unsupportedNumericFormat(_, _, let remainder):
                return remainder
            case .unterminatedString(_, _, let remainder):
                return remainder
            }
        }

    }

    public typealias Location = Token.Location
    
    public init(_ source: String) {
        self.source = source
        self.tokens = []
        self.start = source.unicodeScalars.startIndex
        self.current = source.unicodeScalars.startIndex
        self.line = 1
    }
    
    public func advance() -> UnicodeScalar {
        let scalar = source.unicodeScalars[current]
        current = source.unicodeScalars.index(after:current)
        return scalar
    }
    
    private func append(lexeme: Token.Lexeme) {
        append(lexeme:lexeme, location:locate())
    }

    private func append(lexeme: Token.Lexeme, location: Location) {
        tokens.append(Token(lexeme, location))
    }

    private func isAlpha(_ scalar: UnicodeScalar) -> Bool {
        return CharacterSet.letters.contains(scalar) || scalar == "_"
    }
    
    private func isDigit(_ scalar: UnicodeScalar) -> Bool {
        return CharacterSet.decimalDigits.contains(scalar)
    }
    
    private func locate() -> Location {
        return locate(startingAt:start)
    }

    private func locateEOL() -> Location {
        /// At a '\n' so need to go back one index if it isn't the start of the string
        let index = start == source.unicodeScalars.startIndex ? start : source.unicodeScalars.index(before:start)
        return locate(startingAt:index)
    }
    
    private func locate(startingAt index: String.UnicodeScalarIndex) -> Location {
        var counter = index
        while source.unicodeScalars[counter] != "\n" && counter != source.unicodeScalars.startIndex {
            counter = source.unicodeScalars.index(before:counter)
        }
        /// Fix for the first line that needs to be shifted by one
        let offset = counter == source.unicodeScalars.startIndex ? 1 : 0
        let column = source.unicodeScalars.distance(from:counter, to:start) + offset
        let length = source.unicodeScalars.distance(from:start, to:current)
        return Location(line:line, columns:column...(column + length - 1))
    }

    private func peek() -> UnicodeScalar {
        if current >= source.unicodeScalars.endIndex {
            return UnicodeScalar("\0")
        }
        return source.unicodeScalars[current]
    }

    private func peekNext() -> UnicodeScalar {
        if source.unicodeScalars.index(after:current) >= source.unicodeScalars.endIndex {
            return UnicodeScalar("\0")
        }
        return source.unicodeScalars[source.unicodeScalars.index(after:current)]
    }
    
    /// Remainder of the current line for error reporting
    private func remainder() -> String {
        var index = current
        while !isFinished && source.unicodeScalars[index] != "\n" {
            index = source.unicodeScalars.index(after:index)
        }
        return String(source.unicodeScalars[start..<index])
    }
    
    private func reset() {
        self.tokens = []
        self.start = source.unicodeScalars.startIndex
        self.current = source.unicodeScalars.startIndex
        self.line = 1
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
                append(lexeme:.eol, location:locateEOL())
                line += 1
                
            /// Single-character tokens
            case ":":
                append(lexeme:.colon)
            case ",":
                append(lexeme:.comma)
                
            case ".":
                /// Literals (number) without integer parts (e.g. .125)
                while isDigit(peek()) {
                    let _ = advance()
                }
                /// Attempt numeric conversion
                let valueString = String(source.unicodeScalars[start..<current])
                if let value = Double(valueString) {
                    append(lexeme:.number(value))
                } else {
                    // Failed numeric conversion error
                    throw Error.unsupportedNumericFormat(locate(), tokens, remainder())
                }
                
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
                append(lexeme:.hash(String(source.unicodeScalars[start..<current])))
                
            /// Literals (string)
            case "\"":
                while peek() != "\"" && !isFinished {
                    if peek() == "\n" {
                        throw Error.unterminatedString(locate(), tokens, remainder())
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
                    throw Error.unterminatedString(locate(), tokens, remainder())
                }
                
            /// Literals (number, boolean), identifiers and keywords
            default:
                
                /// Literals (number)
                if isDigit(character) {
                    /// Check for integer part
                    while isDigit(peek()) {
                        let _ = advance()
                    }
                    /// Check for a decimal part
                    if peek() == "." && isDigit(peekNext()) {
                        /// Absorb the "."
                        let _ = advance()
                        /// Absorb the decimal part
                        while isDigit(peek()) {
                            let _ = advance()
                        }
                    }
                    /// Attempt numeric conversion
                    let valueString = String(source.unicodeScalars[start..<current])
                    if let value = Double(valueString) {
                        append(lexeme:.number(value))
                    } else {
                        // Failed numeric conversion error
                        throw Error.unsupportedNumericFormat(locate(), tokens, remainder())
                    }

                /// Literals (boolean), identifiers and keywords
                } else if isAlpha(character) {
                    while isAlpha(peek()) || isDigit(peek()) {
                        let _ = advance()
                    }
                    let value = String(source.unicodeScalars[start..<current])
                    if let keyword = Token.Lexeme.keywords[value] {
                        append(lexeme:keyword)
                    } else {
                        append(lexeme:.identifier(value))
                    }
                
                /// Failure
                } else {
                    // Unexpected character error
                    throw Error.unexpectedCharacter(locate(), tokens, remainder(), character)
                }
            }
        }
        
        /// EOS
        tokens.append(Token(.eos, Location(line:line, column:1)))
        return tokens
    }
    
    private var isFinished: Bool {
        return current >= source.unicodeScalars.endIndex
    }
    
    private let source: String
    private var tokens: [Token]
    private var start: String.UnicodeScalarIndex
    private var current: String.UnicodeScalarIndex
    private var line: Int
}

extension Scanner.Error: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .unexpectedCharacter(_, _, _, let character):
            return "Encountered an unsupported character: '\(character)'"
        case .unsupportedNumericFormat(_, _, _):
            return "Only simple double and integer formats are supported."
        case .unterminatedString(_, _, _):
            return "Strings require a closing double quote and cannot span multiple lines."
        }
    }
}





