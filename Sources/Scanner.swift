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

public enum ScannerErrorType: String {
    case unexpectedCharacter
    case unexpectedNumericFormat
    case unterminatedString
}

public struct ScannerError: CustomStringConvertible {

    public init(type: ScannerErrorType, line: Int, source: String, columns: Range<String.UnicodeScalarIndex>) {
        self.type = type
        self.line = line
        let location = source.unicodeScalars[columns]
        switch type {
        case .unexpectedCharacter:
            self.reason = "Could not parse the following character: '\(location)'"
        case .unexpectedNumericFormat:
            self.reason = "Only double and integer formats are supported: '\(location)'"
        case .unterminatedString:
            self.reason = "Strings require a closing double quote: '\(location)'"
        }
    }
    
    public var description: String {
        return "ScannerError(\(line), \(type), \(reason))"
    }
    
    public let type: ScannerErrorType
    public let line: Int
    public let reason: String
}

public class Scanner {
    
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
    
    private func append(token type: TokenType) {
        let lexeme = String(source.unicodeScalars[start..<current])
        tokens.append(Token(type:type, lexeme:lexeme))
    }

    private func append(error type: ScannerErrorType) {
        errors.append(ScannerError(type:type, line:line, source:source, columns:start..<current))
    }

    private func isAlpha(_ scalar: UnicodeScalar) -> Bool {
        return CharacterSet.letters.contains(scalar) || scalar == "_"
    }
    
    private func isDigit(_ scalar: UnicodeScalar) -> Bool {
        return CharacterSet.decimalDigits.contains(scalar)
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
        if !tokens.isEmpty {
            self.errors = []
            self.tokens = []
            self.start = source.unicodeScalars.startIndex
            self.current = source.unicodeScalars.startIndex
            self.line = 1
        }
    }
    
    public func scan() -> (tokens: [Token], errors: [ScannerError]) {
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
            case "[":
                append(token:.braceLeft)
            case "]":
                append(token:.braceRight)
            case "(":
                append(token:.parenLeft)
            case ")":
                append(token:.parenRight)

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
                append(token:.lessThan)
            case ">":
                append(token:.greaterThan)

            /// Single-character tokens (logical)
            case "!":
                append(token:.exclamation)
            case "&":
                append(token:.ampersand)
            case "|":
                append(token:.verticalBar)

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
                    if let keyword = TokenType.keywords[value] {
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
        tokens.append(Token(type:.end, lexeme:"\0"))
        return (tokens: tokens, errors: errors)
    }
    
    private var isFinished: Bool {
        return current >= source.unicodeScalars.endIndex
    }
    
    private let source: String
    private var tokens: [Token]
    private var errors: [ScannerError]
    private var start: String.UnicodeScalarIndex
    private var current: String.UnicodeScalarIndex
    private var line: Int
}
