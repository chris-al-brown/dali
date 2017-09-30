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
        case degenerateMapKey(Source.Location, String)
        case degenerateArgumentName(Source.Location, String)
        case emptyFunctionBody(Source.Location)
        case invalidArgumentName(Token)
        case invalidAssignment(Source.Location)
        case invalidMapKey(Token)
        case invalidSyntax(Token)
        case trailingComma(Source.Location)
        case unexpectedStreamEnd(Token)
        case unexpectedToken(Token, Token.Lexeme)
        
        public var description: String {
            switch self {
            case .degenerateMapKey(_, let key):
                return "SyntaxError: Found a duplicate map key: '\(key)'"
            case .degenerateArgumentName(_, let name):
                return "SyntaxError: Found a duplicate argument name: '\(name)'"
            case .emptyFunctionBody(_):
                return "SyntaxError: Function bodies must contain at least one return statement."
            case .invalidArgumentName(let token):
                return "SyntaxError: Invalid argument name: '\(token.lexeme)'."
            case .invalidAssignment(_):
                return "SyntaxError: Can not assign to the left side of the expression."
            case .invalidMapKey(let token):
                return "SyntaxError: Invalid map key: '\(token.lexeme)'"
            case .invalidSyntax(let token):
                return "SyntaxError: Unrecognized syntax starting at '\(token.lexeme)'."
            case .trailingComma(_):
                return "SyntaxError: Invalid syntax with trailing comma."
            case .unexpectedStreamEnd(let token):
                return "SyntaxError: Expected more characters to complete expression near '\(token.lexeme)'."
            case .unexpectedToken(let token, let expected):
                return "SyntaxError: Expected to see '\(expected)' but found '\(token.lexeme)' instead."
            }
        }

        public var location: Source.Location {
            switch self {
            case .degenerateMapKey(let location, _):
                return location
            case .degenerateArgumentName(let location, _):
                return location
            case .emptyFunctionBody(let location):
                return location
            case .invalidArgumentName(let token):
                return token.location
            case .invalidAssignment(let location):
                return location
            case .invalidMapKey(let token):
                return token.location
            case .invalidSyntax(let token):
                return token.location
            case .trailingComma(let location):
                return location
            case .unexpectedStreamEnd(let token):
                return token.location
            case .unexpectedToken(let token, _):
                return token.location
            }
        }
    }
    
    public init(_ tokens: [Token]) {
        self.tokens = tokens
        self.expressions = []
        self.currentId = 0
        self.currentIndex = tokens.startIndex
    }
    
    private func advance() -> Token {
        let token = current
        currentIndex += 1
        return token
    }
    
    private func check(_ lexeme: Token.Lexeme) -> Bool {
        if isFinished { return false }
        return current.lexeme == lexeme
    }
    
    private func consume(_ lexeme: Token.Lexeme, strippingCommentsAndNewlines: Bool = true) throws -> Token {
        if isFinished {
            throw Error.unexpectedStreamEnd(current)
        }
        if check(lexeme) {
            let token = advance()
            if strippingCommentsAndNewlines && !isFinished {
                switch current.lexeme {
                /// Ignore trailing comments
                case .hash(let value):
                    let _ = try consume(.hash(value), strippingCommentsAndNewlines:false)
                    let _ = try consume(.newline, strippingCommentsAndNewlines:false)
                /// Ignore trailing blank lines
                case .newline:
                    let _ = try consume(.newline, strippingCommentsAndNewlines:false)
                default:
                    break
                }
            }
            return token
        }
        throw Error.unexpectedToken(current, lexeme)
    }
    
    private func id() -> Int {
        currentId += 1
        return currentId
    }

    private func location(from start: Token) -> Source.Location {
        return location(from:start.location)
    }

    private func location(from start: Source.Location) -> Source.Location {
        return start.lowerBound..<previous.location.upperBound
    }

    public func parse() throws -> [Expression] {
        reset()
        while !isFinished {
            switch current.lexeme {
            /// Ignore comment lines
            case .hash(let value):
                let _ = try consume(.hash(value), strippingCommentsAndNewlines:false)
                let _ = try consume(.newline, strippingCommentsAndNewlines:false)
            /// Ignore blank lines
            case .newline:
                let _ = try consume(.newline, strippingCommentsAndNewlines:false)
            /// Multiple expressions delimited by commas
            case .comma:
                let _ = try consume(.comma, strippingCommentsAndNewlines:false)
            default:
                expressions.append(try parseExpression())
            }
        }
        return expressions
    }
    
    private func parseArgumentName() throws -> Token.Identifier {
        if case let .identifier(value) = current.lexeme {
            let _ = try consume(.identifier(value))
            return value
        }
        throw Error.invalidArgumentName(current)
    }
    
    private func parseBinary(_ lhs: Expression, _ precedence: Int = 0) throws -> Expression {
        var lhs = lhs
        while true {
            guard let binary = Expression.BinaryOperator(current.lexeme), binary.precedence >= precedence else {
                return lhs
            }
            let _ = try consume(binary.lexeme)
            var rhs = try parseUnary()
            if let nextBinary = Expression.BinaryOperator(current.lexeme), binary.precedence < nextBinary.precedence {
                rhs = try parseBinary(rhs, binary.precedence + 1)
            }
            lhs = Expression(id(), .binary(lhs, binary, rhs), location(from:lhs.location))
        }
    }
    
    private func parseBoolean(_ value: Bool) throws -> Expression {
        let start = current
        let _ = try consume(.boolean(value))
        return Expression(id(), .boolean(value), location(from:start))
    }

    private func parseCall(_ lhs: Expression) throws -> Expression {
        switch current.lexeme {
        case .parenLeft:
            let _ = try consume(.parenLeft)
            var parameters: [Token.Identifier: Expression] = [:]
            while !check(.parenRight) {
                let mark = current
                let name = try parseArgumentName()
                let _ = try consume(.colon)
                let value = try parseExpression()
                if parameters[name] == nil {
                    parameters[name] = value
                } else {
                    throw Error.degenerateArgumentName(location(from:mark), name)
                }
                if check(.comma) {
                    let _ = try consume(.comma)
                    if check(.parenRight) {
                        throw Error.trailingComma(previous.location)
                    }
                }
            }
            let _ = try consume(.parenRight)
            return try parseCall(Expression(id(), .call(lhs, parameters), location(from:lhs.location)))
        case .squareLeft:
            let _ = try consume(.squareLeft)
            let index = try parseExpression()
            let _ = try consume(.squareRight)
            return try parseCall(Expression(id(), .get(lhs, index), location(from:lhs.location)))
        default:
            return lhs
        }
    }
    
    private func parseExpression() throws -> Expression {
        let start = current
        let unary = try parseUnary()
        let lhs = try parseBinary(unary)
        if check(.colon) {
            let _ = try consume(.colon)
            let rhs = try parseExpression()
            switch lhs.symbol {
            case .get(let llhs, let index):
                return Expression(id(), .set(llhs, index, rhs), location(from:start))
            case .variable(let name):
                return Expression(id(), .assign(name, rhs), location(from:start))
            default:
                throw Error.invalidAssignment(location(from:start))
            }
        }
        return lhs
    }
    
    private func parseFunction() throws -> Expression {
        let start = current
        let _ = try consume(.at)
        let _ = try consume(.parenLeft)
        var arguments: Set<Token.Identifier> = []
        while !check(.parenRight) {
            switch current.lexeme {
            case .identifier(let name):
                let _ = try consume(.identifier(name))
                if arguments.contains(name) {
                    throw Error.degenerateArgumentName(previous.location, name)
                } else {
                    arguments.insert(name)
                }
            default:
                throw Error.invalidArgumentName(current)
            }
            if check(.comma) {
                let _ = try consume(.comma)
                if check(.parenRight) {
                    throw Error.trailingComma(previous.location)
                }
            }
        }
        let _ = try consume(.parenRight)
        let _ = try consume(.curlyLeft)
        var body: [Expression] = []
        while !check(.curlyRight) {
            body.append(try parseExpression())
            if check(.end) {
                let _ = try consume(.end)
            }
        }
        let _ = try consume(.curlyRight)
        if body.isEmpty {
            throw Error.emptyFunctionBody(location(from:start))
        }
        return Expression(id(), .function(Array(arguments), body), location(from:start))
    }

    private func parseGroup() throws -> Expression {
        let _ = try consume(.parenLeft)
        let result = try parseExpression()
        let _ = try consume(.parenRight)
        return result
    }
    
    private func parseIdentifier(_ value: Token.Identifier) throws -> Expression {
        let start = current
        let _ = try consume(.identifier(value))
        return Expression(id(), .variable(value), location(from:start))
    }
    
    private func parseMapKey() throws -> Token.Identifier {
        if case let .identifier(value) = current.lexeme {
            let _ = try consume(.identifier(value))
            return value
        }
        throw Error.invalidMapKey(current)
    }
    
    private func parseKeyword(_ value: Token.Keyword) throws -> Expression {
        let start = current
        let _ = try consume(.keyword(value))
        return Expression(id(), .keyword(value), location(from:start))
    }
    
    private func parseList() throws -> Expression {
        let start = current
        let _ = try consume(.squareLeft)
        var elements: [Expression] = []
        while !check(.squareRight) {
            elements.append(try parseExpression())
            if check(.comma) {
                let _ = try consume(.comma)
                if check(.squareRight) {
                    throw Error.trailingComma(previous.location)
                }
            }
        }
        let _ = try consume(.squareRight)
        return Expression(id(), .list(elements), location(from:start))
    }
    
    private func parseMap() throws -> Expression {
        let start = current
        let _ = try consume(.curlyLeft)
        var elements: [Token.Identifier: Expression] = [:]
        while !check(.curlyRight) {
            let mark = current
            let key = try parseMapKey()
            let _ = try consume(.colon)
            let value = try parseExpression()
            if elements[key] == nil {
                elements[key] = value
            } else {
                throw Error.degenerateMapKey(location(from:mark), key)
            }
            if check(.comma) {
                let _ = try consume(.comma)
                if check(.curlyRight) {
                    throw Error.trailingComma(previous.location)
                }
            }
        }
        let _ = try consume(.curlyRight)
        return Expression(id(), .map(elements), location(from:start))
    }
    
    private func parseNumber(_ value: Double) throws -> Expression {
        let start = current
        let _ = try consume(.number(value))
        return Expression(id(), .number(value), location(from:start))
    }
    
    private func parsePrimary() throws -> Expression {
        switch current.lexeme {
        case .boolean(let value):
            return try parseBoolean(value)
        case .number(let value):
            return try parseNumber(value)
        case .identifier(let value):
            return try parseIdentifier(value)
        case .keyword(let value):
            return try parseKeyword(value)
        case .string(let value):
            return try parseString(value)
        case .parenLeft:
            return try parseGroup()
        case .squareLeft:
            return try parseList()
        case .curlyLeft:
            return try parseMap()
        case .at:
            return try parseFunction()
        default:
            throw Error.invalidSyntax(current)
        }
    }
    
    private func parseString(_ value: String) throws -> Expression {
        let start = current
        let _ = try consume(.string(value))
        return Expression(id(), .string(value), location(from:start))
    }
    
    private func parseUnary() throws -> Expression {
        let start = current
        guard let unary = Expression.UnaryOperator(current.lexeme) else {
            return try parseCall(try parsePrimary())
        }
        let _ = try consume(unary.lexeme)
        return Expression(id(), .unary(unary, try parseUnary()), location(from:start))
    }

    private func reset() {
        expressions.removeAll(keepingCapacity:true)
        currentIndex = tokens.startIndex
    }
    
    private var previous: Token {
        return tokens[currentIndex - 1]
    }
    
    private var current: Token {
        return tokens[currentIndex]
    }
    
    private var isFinished: Bool {
        return current.lexeme == .end
    }

    private let tokens: [Token]
    private var expressions: [Expression]
    private var currentId: Int
    private var currentIndex: Int
}
