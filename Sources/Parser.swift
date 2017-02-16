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

public final class Parser {
    
    public enum Error: Swift.Error, CustomStringConvertible {
        case unexpectedEndOfStream(Token)
        case unexpectedFunctionArgument(Token)
        case unexpectedToken(Token)

        public var description: String {
            switch self {
            case .unexpectedEndOfStream(let token):
                return "Encountered a premature end to the token stream: '\(token.lexeme)'"
            case .unexpectedFunctionArgument(let token):
                return "Encountered an unexpected function argument: '\(token.lexeme)'"
            case .unexpectedToken(let token):
                return "Encountered an unexpected token: '\(token.lexeme)'"
            }
        }

        public var location: Source.Location {
            switch self {
            case .unexpectedEndOfStream(let token):
                return token.location
            case .unexpectedFunctionArgument(let token):
                return token.location
            case .unexpectedToken(let token):
                return token.location
            }
        }
    }

    public init(_ tokens: [Token]) {
        self.tokens = tokens
        self.expressions = []
        self.currentIndex = tokens.startIndex
    }
    
    private func advance() -> Token {
        let token = current
        currentIndex += 1
        return token
    }

    private func check(_ lexeme: Token.Lexeme) -> Bool {
        if isFinishedCurrent { return false }
        return current.lexeme == lexeme
    }
    
    private func checkNext(_ lexeme: Token.Lexeme) -> Bool {
        if isFinishedNext { return false }
        return next.lexeme == lexeme
    }

    private func consume(_ lexeme: Token.Lexeme) throws -> Token {
        if !isFinishedCurrent && check(lexeme) {
            return advance()
        }
        throw Error.unexpectedToken(current)
    }
    
    public func parse() throws -> [AST.Expression] {
        reset()
        while !isFinishedCurrent {
            switch current.lexeme {
            /// Blank line or EOL
            case .end:
                let _ = try consume(.end)
            /// Multiple statements
            case .comma:
                let _ = try consume(.comma)
            /// Comment full or partial line
            case .hash(let value):
                let _ = try consume(.hash(value))
            /// Everything else
            default:
                expressions.append(try parseExpression())
            }
        }
        return expressions
    }
    
    private func parseBoolean(_ value: Bool) throws -> AST.Expression {
        let _ = try consume(.boolean(value))
        return .boolean(value)
    }
    
    private func parseNumber(_ value: Double) throws -> AST.Expression {
        let _ = try consume(.number(value))
        return .number(value)
    }
    
    private func parseString(_ value: String) throws -> AST.Expression {
        let _ = try consume(.string(value))
        return .string(value)
    }

    private func parseVariable(_ value: AST.Identifier) throws -> AST.Expression {
        let _ = try consume(.identifier(value))
        return .variable(value)
    }

    private func parseGroup() throws -> AST.Expression {
        let _ = try consume(.parenLeft)
        let result = try parseExpression()
        let _ = try consume(.parenRight)
        return result
    }

    private func parseList() throws -> AST.Expression {
        let _ = try consume(.squareLeft)
        var elements: [AST.Expression] = []
        while !check(.squareRight) {
            elements.append(try parseExpression())
            if check(.comma) {
                let _ = try consume(.comma)
            }
        }
        let _ = try consume(.squareRight)
        return .list(elements)
    }
    
    private func parseMap() throws -> AST.Expression {
        let _ = try consume(.curlyLeft)
        var elements: [AST.Identifier: AST.Expression] = [:]
        while !check(.curlyRight) {
            switch current.lexeme {
            case .identifier(let key):
                let _ = try parseVariable(key)
                let _ = try consume(.colon)
                elements[key] = try parseExpression()
            default:
                throw Error.unexpectedToken(current)
            }
            if check(.comma) {
                let _ = try consume(.comma)
            }
        }
        let _ = try consume(.curlyRight)
        return .map(elements)
    }
    
    private func parseFunction() throws -> AST.Expression {
        let _ = try consume(.curlyLeft)
        let _ = try consume(.parenLeft)
        /// Args
        var args: [AST.Identifier] = []
        while !check(.parenRight) {
            switch current.lexeme {
            case .identifier(let name):
                let _ = try consume(.identifier(name))
                args.append(name)
            default:
                throw Error.unexpectedFunctionArgument(current)
            }
            if check(.comma) {
                let _ = try consume(.comma)
            }
        }
        let _ = try consume(.parenRight)
        let _ = try consume(.bar)
        /// Body
        var body: [AST.Expression] = []
        while !check(.curlyRight) {
            body.append(try parseExpression())
            if check(.comma) {
                let _ = try consume(.comma)
            } else if check(.end) {
                let _ = try consume(.end)
            }
        }
        let _ = try consume(.curlyRight)
        return .function(args, body)
    }

    private func parsePrimary() throws -> AST.Expression {
        switch current.lexeme {
        case .boolean(let value):
            return try parseBoolean(value)
        case .number(let value):
            return try parseNumber(value)
        case .identifier(let value):
            return try parseVariable(value)
        case .string(let value):
            return try parseString(value)
        case .parenLeft:
            return try parseGroup()
        case .squareLeft:
            return try parseList()
        case .curlyLeft:
            /// Look ahead one token
            if isFinishedNext {
                throw Error.unexpectedEndOfStream(current)
            }
            switch next.lexeme {
            /// '{' '(' => function
            case .parenLeft:
                return try parseFunction()
            /// '{' 'identifier' => map
            case .identifier(_):
                return try parseMap()
            /// '{' '}' => empty map
            case .curlyRight:
                return try parseMap()
            default:
                throw Error.unexpectedToken(next)
            }
        default:
            throw Error.unexpectedToken(current)
        }
    }
    
    private func parseExpression() throws -> AST.Expression {
        let result = try parseUnaryOperator()
        return try parseBinaryOperator(result)
    }
    
    private func parseBinaryOperator(_ lhs: AST.Expression, _ precedence: Int = 0) throws -> AST.Expression {
        var lhs = lhs
        while true {
            guard let binary = AST.BinaryOperator(current.lexeme) else {
                return lhs
            }
            if binary.precedence < precedence {
                return lhs
            }
            var rhs: AST.Expression
            switch binary {
            case .get:
                rhs = try parseGetOperatorArguments()
            case .call:
                rhs = try parseCallOperatorArguments()
            default:
                let _ = try consume(binary.lexeme)
                rhs = try parseUnaryOperator()
            }
            let nextBinary = AST.BinaryOperator(current.lexeme)
            let nextPrecedence = nextBinary?.precedence ?? -1
            if precedence < nextPrecedence {
                rhs = try parseBinaryOperator(rhs, precedence + 1)
            }
            lhs = .binary(lhs, binary, rhs)
        }
    }
    
    /// TODO: Include keyword arguments here (a.k.a map-like)
    private func parseCallOperatorArguments() throws -> AST.Expression {
        let _ = try consume(.parenLeft)
        var elements: [AST.Expression] = []
        while !check(.parenRight) {
            elements.append(try parseExpression())
            if check(.comma) {
                let _ = try consume(.comma)
            }
        }
        let _ = try consume(.parenRight)
        return .list(elements)
    }

    /// TODO: Restrict to just variable lookup and not full expressions
    private func parseGetOperatorArguments() throws -> AST.Expression {
        let _ = try consume(.squareLeft)
        let result = try parseExpression()
        let _ = try consume(.squareRight)
        return result
    }
    
    private func parseUnaryOperator() throws -> AST.Expression {
        guard let unary = AST.UnaryOperator(current.lexeme) else {
            return try parsePrimary()
        }
        let _ = try consume(unary.lexeme)
        return .unary(unary, try parseUnaryOperator())
    }
    
    private func reset() {
        expressions.removeAll(keepingCapacity:true)
        currentIndex = tokens.startIndex
    }
    
    private var current: Token {
        return tokens[currentIndex]
    }

    private var isFinishedCurrent: Bool {
        return currentIndex >= tokens.endIndex
    }
    
    private var isFinishedNext: Bool {
        return currentIndex + 1 >= tokens.endIndex
    }

    private var next: Token {
        return tokens[currentIndex + 1]
    }

    private let tokens: [Token]
    private var expressions: [AST.Expression]
    private var currentIndex: Int
}
