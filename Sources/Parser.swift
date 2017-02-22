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
        case invalidArgumentName(Token)
        case invalidAssignment(Source.Location)
        case invalidIndex(Source.Location)
        case invalidMapKey(Token)
        case invalidSyntax(Token)
        case invalidValue(Source.Location)
        case trailingComma(Source.Location)
        case unexpectedStreamEnd(Token)
        case unexpectedToken(Token, Token.Lexeme)
        
        public var description: String {
            switch self {
            case .degenerateMapKey(_, let key):
                return "Found a duplicate map key: '\(key)'"
            case .degenerateArgumentName(_, let name):
                return "Found a duplicate argument name: '\(name)'"
            case .invalidArgumentName(let token):
                return "Invalid argument name: '\(token.lexeme)'."
            case .invalidAssignment(_):
                return "Can not assign to the left side of the expression."
            case .invalidIndex(_):
                return "Can not use an assignment or setter as an index type."
            case .invalidMapKey(let token):
                return "Invalid map key: '\(token.lexeme)'"
            case .invalidSyntax(let token):
                return "Invalid syntax starting at '\(token.lexeme)'."
            case .invalidValue(_):
                return "Can not use an assignment or setter as a value type."
            case .trailingComma(_):
                return "Invalid syntax with trailing comma."
            case .unexpectedStreamEnd(let token):
                return "Expected more tokens starting at '\(token.lexeme)'."
            case .unexpectedToken(let token, let expected):
                return "Expected to see '\(expected)' but found '\(token.lexeme)'."
            }
        }

        public var location: Source.Location {
            switch self {
            case .degenerateMapKey(let location, _):
                return location
            case .degenerateArgumentName(let location, _):
                return location
            case .invalidArgumentName(let token):
                return token.location
            case .invalidAssignment(let location):
                return location
            case .invalidIndex(let location):
                return location
            case .invalidMapKey(let token):
                return token.location
            case .invalidSyntax(let token):
                return token.location
            case .invalidValue(let location):
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
    
    private func location(startingAt start: Token) -> Source.Location {
        let begin = start.location
        let end = previous.location
        return begin.lowerBound..<end.upperBound
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
            /// Multiple expressions delimited by commas
            case .comma:
                let _ = try consume(.comma, strippingCommentsAndNewlines:false)
            default:
                expressions.append(try parseExpression())
            }
        }
        return expressions
    }
    
    private func parseArgumentName() throws -> AST.Identifier {
        if case let .identifier(value) = current.lexeme {
            let _ = try consume(.identifier(value))
            return value
        }
        throw Error.invalidArgumentName(current)
    }
    
    private func parseBinary(_ lhs: AST.Expression, _ precedence: Int = 0) throws -> AST.Expression {
        var lhs = lhs
        while true {
            guard let binary = AST.BinaryOperator(current.lexeme), binary.precedence >= precedence else {
                return lhs
            }
            let _ = try consume(binary.lexeme)
            var rhs = try parseUnary()
            if let nextBinary = AST.BinaryOperator(current.lexeme), binary.precedence < nextBinary.precedence {
                rhs = try parseBinary(rhs, binary.precedence + 1)
            }
            lhs = .binary(lhs, binary, rhs)
        }
    }
    
    private func parseBoolean(_ value: Bool) throws -> AST.Expression {
        let _ = try consume(.boolean(value))
        return .primary(.boolean(value))
    }

    private func parseCall(_ lhs: AST.Expression) throws -> AST.Expression {
        switch current.lexeme {
        case .parenLeft:
            let _ = try consume(.parenLeft)
            var parameters: [AST.Identifier: AST.Expression] = [:]
            while !check(.parenRight) {
                let mark = current
                let name = try parseArgumentName()
                let _ = try consume(.colon)
                let value = try parseValue()
                if parameters[name] == nil {
                    parameters[name] = value
                } else {
                    throw Error.degenerateArgumentName(location(startingAt:mark), name)
                }
                if check(.comma) {
                    let _ = try consume(.comma)
                    if check(.parenRight) {
                        throw Error.trailingComma(previous.location)
                    }
                }
            }
            let _ = try consume(.parenRight)
            return try parseCall(.call(lhs, parameters))
        case .squareLeft:
            let _ = try consume(.squareLeft)
            let index = try parseIndex()
            let _ = try consume(.squareRight)
            return try parseCall(.get(lhs, index))
        default:
            return lhs
        }
    }
    
    private func parseExpression() throws -> AST.Expression {
        let mark = current
        let unary = try parseUnary()
        let lhs = try parseBinary(unary)
        if check(.colon) {
            let _ = try consume(.colon)
            /// Right-hand side must be a value type (not a setter or assignment)
            let rhs = try parseValue()
            switch lhs {
            case .get(let llhs, let index):
                return .set(llhs, index, rhs)
            case .primary(let value):
                switch value {
                case .identifier(let name):
                    return .assign(name, rhs)
                default:
                    throw Error.invalidAssignment(location(startingAt:mark))
                }
            default:
                throw Error.invalidAssignment(location(startingAt:mark))
            }
        }
        return lhs
    }
    
    private func parseFunction() throws -> AST.Expression {
        let _ = try consume(.at)
        let _ = try consume(.parenLeft)
        var arguments: Set<AST.Identifier> = []
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
        var body: [AST.Expression] = []
        while !check(.curlyRight) {
            body.append(try parseExpression())
            if check(.end) {
                let _ = try consume(.end)
            }
        }
        let _ = try consume(.curlyRight)
        return .primary(.function(Array(arguments), body))
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
        let mark = current
        let index = try parseExpression()
        switch index {
        case .assign(_, _):
            throw Error.invalidIndex(location(startingAt:mark))
        case .binary(_, _, _):
            return index
        case .call(_, _):
            return index
        case .get(_, _):
            return index
        case .primary(_):
            return index
        case .set(_, _, _):
            throw Error.invalidIndex(location(startingAt:mark))
        case .unary(_, _):
            return index
        }
    }
    
    private func parseMapKey() throws -> AST.Identifier {
        if case let .identifier(value) = current.lexeme {
            let _ = try consume(.identifier(value))
            return value
        }
        throw Error.invalidMapKey(current)
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
                    throw Error.trailingComma(previous.location)
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
            let mark = current
            let key = try parseMapKey()
            let _ = try consume(.colon)
            let value = try parseValue()
            if elements[key] == nil {
                elements[key] = value
            } else {
                throw Error.degenerateMapKey(location(startingAt:mark), key)
            }
            if check(.comma) {
                let _ = try consume(.comma)
                if check(.curlyRight) {
                    throw Error.trailingComma(previous.location)
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
            throw Error.invalidSyntax(current)
        }
    }
    
    private func parseString(_ value: String) throws -> AST.Expression {
        let _ = try consume(.string(value))
        return .primary(.string(value))
    }
    
    private func parseUnary() throws -> AST.Expression {
        guard let unary = AST.UnaryOperator(current.lexeme) else {
            return try parseCall(try parsePrimary())
        }
        let _ = try consume(unary.lexeme)
        return .unary(unary, try parseUnary())
    }

    private func parseValue() throws -> AST.Expression {
        let mark = current
        let value = try parseExpression()
        switch value {
        case .assign(_, _):
            throw Error.invalidValue(location(startingAt:mark))
        case .binary(_, _, _):
            return value
        case .call(_, _):
            return value
        case .get(_, _):
            return value
        case .primary(_):
            return value
        case .set(_, _, _):
            throw Error.invalidValue(location(startingAt:mark))
        case .unary(_, _):
            return value
        }
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
    private var expressions: [AST.Expression]
    private var currentIndex: Int
}
