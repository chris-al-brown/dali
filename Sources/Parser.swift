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

    private func check(_ lexeme: TokenLexeme) -> Bool {
        if isFinished { return false }
        return current.lexeme == lexeme
    }
    
    private func consume(_ lexeme: TokenLexeme) throws -> Token {
        if isFinished {
            throw ParserError.unexpectedStreamEnd(current)
        }
        if check(lexeme) {
            return advance()
        }
        throw ParserError.unexpectedToken(current, lexeme)
    }
    
    private func location(from start: Token) -> SourceLocation {
        return location(from:start.location)
    }

    private func location(from start: SourceLocation) -> SourceLocation {
        return start.lowerBound..<previous.location.upperBound
    }

    public func parse() throws -> [ASTStatement] {
        reset()
        while !isFinished {
            statements.append(try parseDeclaration())
        }
        return statements
    }

    private func parseBinary(_ lhs: ASTExpression, _ precedence: Int = 0) throws -> ASTExpression {
        var lhs = lhs
        while true {
            guard let binary = ASTBinaryOperator(current.lexeme), binary.precedence >= precedence else {
                return lhs
            }
            let _ = try consume(binary.lexeme)
            var rhs = try parseUnary()
            if let nextBinary = ASTBinaryOperator(current.lexeme), binary.precedence < nextBinary.precedence {
                rhs = try parseBinary(rhs, binary.precedence + 1)
            }
            lhs = ASTExpression(.binary(lhs, binary, rhs), location(from:lhs.location))
        }
    }

    private func parseBoolean(_ value: Bool) throws -> ASTExpression {
        let start = current
        let _ = try consume(.boolean(value))
        return ASTExpression(.boolean(value), location(from:start))
    }

    private func parseCall(_ lhs: ASTExpression) throws -> ASTExpression {
        switch current.lexeme {
        case .parenLeft:
            let _ = try consume(.parenLeft)
            var arguments: [ASTExpression] = []
            while !check(.parenRight) {
                arguments.append(try parseExpression())
                if check(.comma) {
                    let _ = try consume(.comma)
                }
            }
            let _ = try consume(.parenRight)
            return try parseCall(ASTExpression(.call(lhs, arguments), location(from:lhs.location)))
        default:
            return lhs
        }
    }
    
    private func parseColor(_ value: String) throws -> ASTExpression {
        let start = current
        let _ = try consume(.color(value))
        let scanner = Foundation.Scanner(string:value)
        var uint32: UInt32 = 0
        scanner.scanHexInt32(&uint32)
        return ASTExpression(.color(uint32), location(from:start))
    }
    
    private func parseDeclaration() throws -> ASTStatement {
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

    private func parseFuncDeclaration() throws -> ASTStatement {
        let start = current
        let _ = try consume(.keyword(.func))
        switch current.lexeme {
        case .identifier(let name):
            let _ = try consume(.identifier(name))
            let _ = try consume(.colon)
            let _ = try consume(.parenLeft)
            var args: [TokenIdentifier] = []
            while !check(.parenRight) {
                switch current.lexeme {
                case .identifier(let value):
                    let _ = try consume(.identifier(value))
                    args.append(value)
                    if check(.comma) {
                        let _ = try consume(.comma)
                    }
                default:
                    throw ParserError.invalidArgument(current)
                }
            }
            let _ = try consume(.parenRight)
            let _ = try consume(.curlyLeft)
            var body: [ASTStatement] = []
            while !check(.curlyRight) {
                body.append(try parseDeclaration())
            }
            let _ = try consume(.curlyRight)
            return ASTStatement(.declaration(.function(name, args, body)), location(from:start))
        default:
            throw ParserError.invalidFuncDeclaration(location(from:start))
        }
    }
    
    private func parseVarDeclaration() throws -> ASTStatement {
        let start = current
        let _ = try consume(.keyword(.var))
        switch current.lexeme {
        case .identifier(let lvalue):
            let _ = try consume(.identifier(lvalue))
            let _ = try consume(.colon)
            let rvalue = try parseExpression()
            return ASTStatement(.declaration(.variable(lvalue, rvalue)), location(from:start))
        default:
            throw ParserError.invalidVarDeclaration(location(from:start))
        }
    }
    
    private func parseStatement() throws -> ASTStatement {
        return try parseExpressionStatement()
    }

    private func parseExpressionStatement() throws -> ASTStatement {
        let rvalue = try parseExpression()
        return ASTStatement(.expression(rvalue), current.location)
    }
    
    private func parseExpression() throws -> ASTExpression {
        let start = current
        let unary = try parseUnary()
        let lhs = try parseBinary(unary)
        if check(.colon) {
            let _ = try consume(.colon)
            let rhs = try parseExpression()
            switch lhs.type {
            case .getter(let name):
                return ASTExpression(.setter(name, rhs), location(from:start))
            default:
                throw ParserError.invalidAssignment(location(from:start))
            }
        }
        return lhs
    }

    private func parseGroup() throws -> ASTExpression {
        let _ = try consume(.parenLeft)
        let result = try parseExpression()
        let _ = try consume(.parenRight)
        return result
    }

    private func parseIdentifier(_ value: TokenIdentifier) throws -> ASTExpression {
        let start = current
        let _ = try consume(.identifier(value))
        return ASTExpression(.getter(value), location(from:start))
    }

    private func parseKeyword(_ value: TokenKeyword) throws -> ASTExpression {
        let start = current
        let _ = try consume(.keyword(value))
        return ASTExpression(.keyword(value), location(from:start))
    }
    
    private func parseNumber(_ value: Double) throws -> ASTExpression {
        let start = current
        let _ = try consume(.number(value))
        return ASTExpression(.number(value), location(from:start))
    }

    private func parsePrimary() throws -> ASTExpression {
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
            throw ParserError.invalidSyntax(current)
        }
    }
    
    private func parseString(_ value: String) throws -> ASTExpression {
        let start = current
        let _ = try consume(.string(value))
        return ASTExpression(.string(value), location(from:start))
    }

    private func parseUnary() throws -> ASTExpression {
        let start = current
        guard let unary = ASTUnaryOperator(current.lexeme) else {
            return try parseCall(try parsePrimary())
        }
        let _ = try consume(unary.lexeme)
        return ASTExpression(.unary(unary, try parseUnary()), location(from:start))
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
    private var statements: [ASTStatement]
    private var currentId: Int
    private var currentIndex: Int
}

public enum ParserError: Swift.Error, CustomStringConvertible {
    case invalidArgument(Token)
    case invalidAssignment(SourceLocation)
    case invalidFuncDeclaration(SourceLocation)
    case invalidSyntax(Token)
    case invalidVarDeclaration(SourceLocation)
    case unexpectedStreamEnd(Token)
    case unexpectedToken(Token, TokenLexeme)
    
    public var description: String {
        switch self {
        case .invalidArgument(let token):
            return "Unexpected closure argument at '\(token.lexeme)'"
        case .invalidAssignment(_):
            return "Can not assign to the left side of the expression."
        case .invalidFuncDeclaration(_):
            return "Invalid syntax for a function declaration."
        case .invalidSyntax(let token):
            return "Unrecognized syntax starting at '\(token.lexeme)'."
        case .invalidVarDeclaration(_):
            return "Invalid syntax for a variable declaration."
        case .unexpectedStreamEnd(let token):
            return "Expected more characters to complete expression near '\(token.lexeme)'."
        case .unexpectedToken(let token, let expected):
            return "Expected to see '\(expected)' but found '\(token.lexeme)' instead."
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
        case .unexpectedStreamEnd(let token):
            return token.location
        case .unexpectedToken(let token, _):
            return token.location
        }
    }
}
