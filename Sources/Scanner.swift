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

public enum ScannerError: Error {
    case unexpectedCharacter
    case unexpectedNumericFormat
    case unterminatedString
}

extension ScannerError: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .unexpectedCharacter:
            return "Encountered an unsupported character."
        case .unexpectedNumericFormat:
            return "Only double and integer formats are supported."
        case .unterminatedString:
            return "Strings require a closing double quote."
        }
    }
}

public final class Scanner {
    
    public enum Result {
        case success([(Token, Source.Location)])
        case failure([(ScannerError, Source.Location)])
    }
    
    public init(source: String) {
        self.source = source
        self.errors = []
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
    
    private func append(token: Token) {
        tokens.append((token, locate()))
    }

    private func append(error: ScannerError) {
        errors.append((error, locate()))
    }

    private func isAlpha(_ scalar: UnicodeScalar) -> Bool {
        return CharacterSet.letters.contains(scalar) || scalar == "_"
    }
    
    private func isDigit(_ scalar: UnicodeScalar) -> Bool {
        return CharacterSet.decimalDigits.contains(scalar)
    }
    
    /// TODO: This is brittle and doesn't report correct lines/columns for multiline strings
    
    private func locate() -> Source.Location {
        var counter = start
        while source.unicodeScalars[counter] != "\n" && counter != source.unicodeScalars.startIndex {
            counter = source.unicodeScalars.index(before:counter)
        }
        let column = counter == source.unicodeScalars.startIndex ? 1 : source.unicodeScalars.distance(from:counter, to:start)
        let length = source.unicodeScalars.distance(from:start, to:current)
        return Source.Location(line:line, columns:column..<column+length)
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
    
    private func reset() {
        self.errors = []
        self.tokens = []
        self.start = source.unicodeScalars.startIndex
        self.current = source.unicodeScalars.startIndex
        self.line = 1
    }
    
    public func scan() -> Result {
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
                line += 1
                
            /// Single-character tokens
            case ":":
                append(token:.colon)
            case ",":
                append(token:.comma)
            case ".":
                append(token:.dot)
            case "{":
                append(token:.curlyLeft)
            case "}":
                append(token:.curlyRight)
            case "(":
                append(token:.parenLeft)
            case ")":
                append(token:.parenRight)
            case "[":
                append(token:.squareLeft)
            case "]":
                append(token:.squareRight)

            /// Single-character tokens (arithmetic)
            case "+":
                append(token:.plus)
            case "-":
                append(token:.minus)
            case "*":
                append(token:.star)
            case "/":
                append(token:.slash)

            /// Single-character tokens (comparison)
            case "=":
                append(token:.equal)
            case "<":
                append(token:.carrotLeft)
            case ">":
                append(token:.carrotRight)

            /// Single-character tokens (logical)
            case "!":
                append(token:.exclamation)
            case "&":
                append(token:.ampersand)
            case "|":
                append(token:.bar)

            /// Single-character tokens (comments)
            case "#":
                while peek() != "\n" && !isFinished {
                    let _ = advance()
                }
                append(token:.hash)
                
            /// Literals (string)
            case "\"":
                var newlines = 0
                while peek() != "\"" && !isFinished {
                    if peek() == "\n" {
                        newlines += 1
                    }
                    let _ = advance()
                }
                if !isFinished {
                    // The closing "
                    let _ = advance()
                    // Trim the surrounding quotes
                    let lower = source.unicodeScalars.index(after:start)
                    let upper = source.unicodeScalars.index(before:current)
                    append(token:.string(String(source.unicodeScalars[lower..<upper])))
                } else {
                    // Unterminated string error
                    append(error:.unterminatedString)
                }
                line += newlines
                
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
                    if let value = Double(String(source.unicodeScalars[start..<current])) {
                        append(token:.number(value))
                    } else {
                        // Failed numeric conversion error
                        append(error:.unexpectedNumericFormat)
                    }

                /// Literals (boolean), identifiers and keywords
                } else if isAlpha(character) {
                    while isAlpha(peek()) || isDigit(peek()) {
                        let _ = advance()
                    }
                    let value = String(source.unicodeScalars[start..<current])
                    if let keyword = Token.keywords[value] {
                        append(token:keyword)
                    } else {
                        append(token:.identifier(value))
                    }
                
                /// Failure
                } else {
                    // Unexpected character error
                    append(error:.unexpectedCharacter)
                }
            }
        }
        
        /// EOF
        tokens.append((.eof, Source.Location(line:line, column:1)))
        return errors.isEmpty ? .success(tokens) : .failure(errors)
    }
    
    private var isFinished: Bool {
        return current >= source.unicodeScalars.endIndex
    }
    
    private let source: String
    private var tokens: [(Token, Source.Location)]
    private var errors: [(ScannerError, Source.Location)]
    private var start: String.UnicodeScalarIndex
    private var current: String.UnicodeScalarIndex
    private var line: Int
}
