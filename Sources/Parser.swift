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
// Parser.swift
// 01/24/2017
// Used to convert tokens into an AST
// -----------------------------------------------------------------------------

import Foundation

public enum ParserError: Error {
    case unterminatedExpression
}

extension ParserError: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .unterminatedExpression:
            return "Expected a closing ')' to finish the expression."
        }
    }
}

public final class Parser {
    
    public enum Result {
        case success([(AST.Expression, Source.Location)])
        case failure([(ParserError, Source.Location)])
    }
 
    public init(tokens: [(Token, Source.Location)]) {
        self.tokens = tokens
        self.expressions = []
        self.errors = []
        self.start = tokens.startIndex
        self.current = tokens.startIndex
    }
    
    private func advance() -> Token {
        let token = tokens[current]
        current = tokens.index(after:current)
        return token.0
    }

    private func append(expression: AST.Expression) {
        expressions.append((expression, locate()))
    }
    
    private func append(error: ParserError) {
        errors.append((error, locate()))
    }

    private func locate() -> Source.Location {
        return tokens[start].1
    }

    private func peek() -> Token {
        if current >= tokens.endIndex {
            return .eof
        }
        return tokens[current].0
    }
    
    private func reset() {
        self.expressions = []
        self.errors = []
        self.start = tokens.startIndex
        self.current = tokens.startIndex
    }
    
    public func parse() -> Result {
        /// Reset the parser
        reset()
        
        /// Start converting tokens to expressions
        while !isFinished {
            
            /// Advance to next token
            start = current
            let token = advance()
            switch token {
                
            /// Parentheses
            case .parenLeft:
                while peek() != .parenRight && !isFinished {
                    let _ = advance()
                }
                if !isFinished {
                    /// append an expression formed from the sandwich interior
                } else {
                    // Unterminated expression error
                    append(error:.unterminatedExpression)
                }
                
            /// Literals
            case .number(let value):
                append(expression:.number(value))
            case .string(let value):
                append(expression:.string(value))
            case .boolean(let value):
                append(expression:.boolean(value))
                
            /// Identifier
            case .identifier(let value):
                if peek() == .parenLeft {
                    /// Function call identifier
                    
                } else {
                    /// Simple identifier
                    append(expression:.variable(value))
                }
                
            /// Ignore comments
            case .hash:
                break
                
            default:
                break
            }
        }
        
        return errors.isEmpty ? .success(expressions) : .failure(errors)
    }

    private var isFinished: Bool {
        return current >= tokens.endIndex
    }

    private var tokens: [(Token, Source.Location)]
    private var expressions: [(AST.Expression, Source.Location)]
    private var errors: [(ParserError, Source.Location)]
    private var start: Int
    private var current: Int
}
