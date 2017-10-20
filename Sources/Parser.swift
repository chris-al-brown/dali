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
        case invalidArgument(Token)
        case invalidAssignment(SourceLocation)
        case invalidFuncDeclaration(SourceLocation)
        case invalidSyntax(Token)
        case invalidVarDeclaration(SourceLocation)
        case trailingComma(SourceLocation)
        case unexpectedStreamEnd(Token)
        case unexpectedToken(Token, Token.Lexeme)

        public var description: String {
            switch self {
            case .invalidArgument(let token):
                return "SyntaxError: Unexpected closure argument at '\(token.lexeme)'"
            case .invalidAssignment(_):
                return "SyntaxError: Can not assign to the left side of the expression."
            case .invalidFuncDeclaration(_):
                return "SyntaxError: Invalid syntax for a function declaration."
            case .invalidSyntax(let token):
                return "SyntaxError: Unrecognized syntax starting at '\(token.lexeme)'."
            case .invalidVarDeclaration(_):
                return "SyntaxError: Invalid syntax for a variable declaration."
            case .trailingComma(_):
                return "SyntaxError: Invalid syntax with trailing comma."
            case .unexpectedStreamEnd(let token):
                return "SyntaxError: Expected more characters to complete expression near '\(token.lexeme)'."
            case .unexpectedToken(let token, let expected):
                return "SyntaxError: Expected to see '\(expected)' but found '\(token.lexeme)' instead."
            }
        }

        public var location: SourceLocation {
            switch self {
            case .invalidArgument(let token):
                return token.location
            case .invalidAssignment(let location):
                return location
            case .invalidFuncDeclaration(let location):
                return location
            case .invalidSyntax(let token):
                return token.location
            case .invalidVarDeclaration(let location):
                return location
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
        self.statements = []
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

    private func consume(_ lexeme: Token.Lexeme) throws -> Token {
        if isFinished {
            throw Error.unexpectedStreamEnd(current)
        }
        if check(lexeme) {
            return advance()
        }
        throw Error.unexpectedToken(current, lexeme)
    }

    private func location(from start: Token) -> SourceLocation {
        return location(from:start.location)
    }

    private func location(from start: SourceLocation) -> SourceLocation {
        return start.lowerBound..<previous.location.upperBound
    }

    public func parse() throws -> [Statement] {
        reset()
        while !isFinished {
            statements.append(try parseDeclaration())
        }
        return statements
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
            lhs = Expression(.binary(lhs, binary, rhs), location(from:lhs.location))
        }
    }

    private func parseBoolean(_ value: Bool) throws -> Expression {
        let start = current
        let _ = try consume(.boolean(value))
        return Expression(.boolean(value), location(from:start))
    }

    private func parseCall(_ lhs: Expression) throws -> Expression {
        switch current.lexeme {
        case .parenLeft:
            let _ = try consume(.parenLeft)
            var arguments: [Expression] = []
            while !check(.parenRight) {
                arguments.append(try parseExpression())
                if check(.comma) {
                    let _ = try consume(.comma)
                    if check(.parenRight) {
                        throw Error.trailingComma(previous.location)
                    }
                }
            }
            let _ = try consume(.parenRight)
            return try parseCall(Expression(.call(lhs, arguments), location(from:lhs.location)))
        default:
            return lhs
        }
    }
    
    private func parseColor(_ value: String) throws -> Expression {
        let start = current
        let _ = try consume(.color(value))
        let scanner = Foundation.Scanner(string:value)
        var uint32: UInt32 = 0
        scanner.scanHexInt32(&uint32)
        return Expression(.color(uint32), location(from:start))
    }
    
    private func parseDeclaration() throws -> Statement {
        switch current.lexeme {
        case .keyword(let value):
            switch value {
            case .func:
                return try parseFuncDeclaration()
            case .var:
                return try parseVarDeclaration()
            }
        default:
            return try parseStatement()
        }
    }

    private func parseFuncDeclaration() throws -> Statement {
        let start = current
        let _ = try consume(.keyword(.func))
        switch current.lexeme {
        case .identifier(let name):
            let _ = try consume(.identifier(name))
            let _ = try consume(.colon)
            let _ = try consume(.parenLeft)
            var args: [Token.Identifier] = []
            while !check(.parenRight) {
                switch current.lexeme {
                case .identifier(let value):
                    let _ = try consume(.identifier(value))
                    args.append(value)
                    if check(.comma) {
                        let _ = try consume(.comma)
                        if check(.parenRight) {
                            throw Error.trailingComma(previous.location)
                        }
                    }
                default:
                    throw Error.invalidArgument(current)
                }
            }
            let _ = try consume(.parenRight)
            let _ = try consume(.curlyLeft)
            var body: [Statement] = []
            while !check(.curlyRight) {
                body.append(try parseExpressionStatement())
            }
            let _ = try consume(.curlyRight)
            return Statement(.declaration(.function(name, args, body)), location(from:start))
        default:
            throw Error.invalidFuncDeclaration(location(from:start))
        }
    }
    
    private func parseVarDeclaration() throws -> Statement {
        let start = current
        let _ = try consume(.keyword(.var))
        switch current.lexeme {
        case .identifier(let lvalue):
            let _ = try consume(.identifier(lvalue))
            let _ = try consume(.colon)
            let rvalue = try parseExpression()
            let _ = try consume(.semicolon)
            return Statement(.declaration(.variable(lvalue, rvalue)), location(from:start))
        default:
            throw Error.invalidVarDeclaration(location(from:start))
        }
    }
    
    private func parseStatement() throws -> Statement {
        return try parseExpressionStatement()
    }

    private func parseExpressionStatement() throws -> Statement {
        let rvalue = try parseExpression()
        let _ = try consume(.semicolon)
        return Statement(.expression(rvalue), current.location)
    }
    
    private func parseExpression() throws -> Expression {
        let start = current
        let unary = try parseUnary()
        let lhs = try parseBinary(unary)
        if check(.colon) {
            let _ = try consume(.colon)
            let rhs = try parseExpression()
            switch lhs.symbol {
            case .getter(let name):
                return Expression(.setter(name, rhs), location(from:start))
            default:
                throw Error.invalidAssignment(location(from:start))
            }
        }
        return lhs
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
        return Expression(.getter(value), location(from:start))
    }

    private func parseKeyword(_ value: Token.Keyword) throws -> Expression {
        let start = current
        let _ = try consume(.keyword(value))
        return Expression(.keyword(value), location(from:start))
    }
    
    private func parseNumber(_ value: Double) throws -> Expression {
        let start = current
        let _ = try consume(.number(value))
        return Expression(.number(value), location(from:start))
    }

    private func parsePrimary() throws -> Expression {
        switch current.lexeme {
        case .boolean(let value):
            return try parseBoolean(value)
        case .color(let value):
            return try parseColor(value)
        case .parenLeft:
            return try parseGroup()
        case .identifier(let value):
            return try parseIdentifier(value)
        case .keyword(let value):
            return try parseKeyword(value)
        case .number(let value):
            return try parseNumber(value)
        case .string(let value):
            return try parseString(value)
        default:
            throw Error.invalidSyntax(current)
        }
    }
    
    private func parseString(_ value: String) throws -> Expression {
        let start = current
        let _ = try consume(.string(value))
        return Expression(.string(value), location(from:start))
    }

    private func parseUnary() throws -> Expression {
        let start = current
        guard let unary = Expression.UnaryOperator(current.lexeme) else {
            return try parseCall(try parsePrimary())
        }
        let _ = try consume(unary.lexeme)
        return Expression(.unary(unary, try parseUnary()), location(from:start))
    }

    private func reset() {
        statements.removeAll(keepingCapacity:true)
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
    private var statements: [Statement]
    private var currentId: Int
    private var currentIndex: Int
}


