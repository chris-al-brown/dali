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
        case degenerateKey(Token)
        case invalidArgumentName(Token)
        case invalidAssignment(Token)
        case invalidIndex(Token)
        case invalidKey(Token)
        case invalidValue(Token)
        case prematureStreamEnd(Token)
        case trailingToken(Token)
        case unexpectedToken(Token, Token.Lexeme)
        case unsupportedPrimary(Token)

        public var description: String {
            switch self {
            case .degenerateKey(let token):
                return "Degenerate key found: '\(token.lexeme)'"
            case .invalidArgumentName(let token):
                return "Invalid argument name: '\(token.lexeme)'"
            case .invalidAssignment(let token):
                return "Invalid right-hand assignment: '\(token.lexeme)'"
            case .invalidIndex(let token):
                return "Invalid index: '\(token.lexeme)'"
            case .invalidKey(let token):
                return "Invalid map key: '\(token.lexeme)'"
            case .invalidValue(let token):
                return "Invalid value: '\(token.lexeme)'"
            case .prematureStreamEnd(let token):
                return "Token stream ended prematurely: '\(token.lexeme)'"
            case .trailingToken(let token):
                return "Trailing '\(token.lexeme)'"
            case .unexpectedToken(let token, let expected):
                return "Expected to see '\(expected)' but found '\(token.lexeme)'"
            case .unsupportedPrimary(let token):
                return "Unsupported primary '\(token.lexeme)'."
            }
        }

        public var location: Source.Location {
            switch self {
            case .degenerateKey(let token):
                return token.location
            case .invalidArgumentName(let token):
                return token.location
            case .invalidAssignment(let token):
                return token.location
            case .invalidIndex(let token):
                return token.location
            case .invalidKey(let token):
                return token.location
            case .invalidValue(let token):
                return token.location
            case .prematureStreamEnd(let token):
                return token.location
            case .trailingToken(let token):
                return token.location
            case .unexpectedToken(let token, _):
                return token.location
            case .unsupportedPrimary(let token):
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
        if isFinished { return false }
        return current.lexeme == lexeme
    }
    
    private func consume(_ lexeme: Token.Lexeme, strippingCommentsAndNewlines: Bool = true) throws -> Token {
        if isFinished {
            throw Error.prematureStreamEnd(current)
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
    
    public func parse() throws -> [AST.Expression] {
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
            default:
                expressions.append(try parseExpression())
            }
        }
        return expressions
    }
    
    private func parseArguments(_ close: Token.Lexeme) throws -> [AST.Identifier] {
        var arguments: [AST.Identifier] = []
        while !check(close) {
            switch current.lexeme {
            case .identifier(let name):
                let _ = try consume(.identifier(name))
                arguments.append(name)
            default:
                throw Error.invalidArgumentName(current)
            }
            if check(.comma) {
                let _ = try consume(.comma)
                if check(close) {
                    throw Error.trailingToken(current)
                }
            }
        }
        return arguments
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
            let _ = try consume(binary.lexeme)
            var rhs = try parseUnaryOperator()
            let nextBinary = AST.BinaryOperator(current.lexeme)
            let nextPrecedence = nextBinary?.precedence ?? -1
            if precedence < nextPrecedence {
                rhs = try parseBinaryOperator(rhs, precedence + 1)
            }
            lhs = .binary(lhs, binary, rhs)
        }
    }
    
    private func parseBody(_ close: Token.Lexeme) throws -> [AST.Expression] {
        var body: [AST.Expression] = []
        while !check(close) {
            body.append(try parseExpression())
            if check(.end) {
                let _ = try consume(.end)
            }
        }
        return body
    }
    
    private func parseBoolean(_ value: Bool) throws -> AST.Expression {
        let _ = try consume(.boolean(value))
        return .primary(.boolean(value))
    }

    private func parseCall(_ lvalue: AST.Expression) throws -> AST.Expression {
        switch current.lexeme {
        case .parenLeft:
            let _ = try consume(.parenLeft)
            var parameters: [AST.Identifier: AST.Expression] = [:]
            while !check(.parenRight) {
                let key = try parseKey()
                let _ = try consume(.colon)
                let value = try parseValue()
                if parameters[key] == nil {
                    parameters[key] = value
                } else {
                    throw Error.degenerateKey(current)
                }
                if check(.comma) {
                    let _ = try consume(.comma)
                    if check(.parenRight) {
                        throw Error.trailingToken(current)
                    }
                }
            }
            let _ = try consume(.parenRight)
            return try parseCall(.call(lvalue, parameters))
        case .squareLeft:
            let _ = try consume(.squareLeft)
            let index = try parseIndex()
            let _ = try consume(.squareRight)
            return try parseCall(.get(lvalue, index))
        default:
            return lvalue
        }
    }
    
    private func parseExpression() throws -> AST.Expression {
        let unary = try parseUnaryOperator()
        let lvalue = try parseBinaryOperator(unary)
        if check(.colon) {
            let _ = try consume(.colon)
            let rvalue = try parseExpression()
            switch lvalue {
            case .get(let llvalue, let index):
                return .set(llvalue, index, rvalue)
            case .primary(let primary):
                switch primary {
                case .identifier(let identifier):
                    return .assign(identifier, rvalue)
                default:
                    throw Error.invalidAssignment(current)
                }
            default:
                throw Error.invalidAssignment(current)
            }
        }
        return lvalue
    }
    
    private func parseFunction() throws -> AST.Expression {
        let _ = try consume(.at)
        let _ = try consume(.parenLeft)
        let arguments = try parseArguments(.parenRight)
        let _ = try consume(.parenRight)
        let _ = try consume(.curlyLeft)
        let body = try parseBody(.curlyRight)
        let _ = try consume(.curlyRight)
        return .primary(.function(arguments, body))
    }

    private func parseGroup() throws -> AST.Expression {
        let _ = try consume(.parenLeft)
        let result = try parseExpression()
        let _ = try consume(.parenRight)
        return result
    }
    
    private func parseIdentifier(_ value: AST.Identifier) throws -> AST.Expression {
        let _ = try consume(.identifier(value))
        return .primary(.identifier(value))
    }
    
    private func parseIndex() throws -> AST.Index {
        let token = current
        let index = try parseExpression()
        switch index {
        case .assign(_, _):
            throw Error.invalidIndex(token)
        case .binary(_, _, _):
            return index
        case .call(_, _):
            return index
        case .get(_, _):
            return index
        case .primary(_):
            return index
        case .set(_, _, _):
            throw Error.invalidIndex(token)
        case .unary(_, _):
            return index
        }
    }
    
    private func parseKey() throws -> AST.Identifier {
        if case let .identifier(value) = current.lexeme {
            let _ = try consume(.identifier(value))
            return value
        }
        throw Error.invalidKey(current)
    }
    
    private func parseKeyword(_ value: AST.Keyword) throws -> AST.Expression {
        let _ = try consume(.keyword(value))
        return .primary(.keyword(value))
    }
    
    private func parseList() throws -> AST.Expression {
        let _ = try consume(.squareLeft)
        var elements: [AST.Expression] = []
        while !check(.squareRight) {
            elements.append(try parseValue())
            if check(.comma) {
                let _ = try consume(.comma)
                if check(.squareRight) {
                    throw Error.trailingToken(current)
                }
            }
        }
        let _ = try consume(.squareRight)
        return .primary(.list(elements))
    }
    
    private func parseMap() throws -> AST.Expression {
        let _ = try consume(.curlyLeft)
        var elements: [AST.Identifier: AST.Expression] = [:]
        while !check(.curlyRight) {
            let key = try parseKey()
            let _ = try consume(.colon)
            let value = try parseValue()
            if elements[key] == nil {
                elements[key] = value
            } else {
                throw Error.degenerateKey(current)
            }
            if check(.comma) {
                let _ = try consume(.comma)
                if check(.curlyRight) {
                    throw Error.trailingToken(current)
                }
            }
        }
        let _ = try consume(.curlyRight)
        return .primary(.map(elements))
    }
    
    private func parseNumber(_ value: Double) throws -> AST.Expression {
        let _ = try consume(.number(value))
        return .primary(.number(value))
    }
    
    private func parsePrimary() throws -> AST.Expression {
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
            throw Error.unsupportedPrimary(current)
        }
    }
    
    private func parseString(_ value: String) throws -> AST.Expression {
        let _ = try consume(.string(value))
        return .primary(.string(value))
    }
    
    private func parseUnaryOperator() throws -> AST.Expression {
        guard let unary = AST.UnaryOperator(current.lexeme) else {
            let primary = try parsePrimary()
            return try parseCall(primary)
        }
        let _ = try consume(unary.lexeme)
        return .unary(unary, try parseUnaryOperator())
    }

    private func parseValue() throws -> AST.Expression {
        let token = current
        let value = try parseExpression()
        switch value {
        case .assign(_, _):
            throw Error.invalidValue(token)
        case .binary(_, _, _):
            return value
        case .call(_, _):
            return value
        case .get(_, _):
            return value
        case .primary(_):
            return value
        case .set(_, _, _):
            throw Error.invalidValue(token)
        case .unary(_, _):
            return value
        }
    }

    private func reset() {
        expressions.removeAll(keepingCapacity:true)
        currentIndex = tokens.startIndex
    }
    
    private var current: Token {
        return tokens[currentIndex]
    }
    
    private var isFinished: Bool {
        return current.lexeme == .end
    }

    private let tokens: [Token]
    private var expressions: [AST.Expression]
    private var currentIndex: Int
}
