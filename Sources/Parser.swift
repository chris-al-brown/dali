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

/**
 -------------------
 Parser EBNF grammar
 -------------------

 ? : 0 or 1 occurances
 * : 0 or > occurances
 + : 1 or > occurances
 
 -------------------
 
 program        = statement* eos
 
 statement      = expression eol
 
 -------TODO--------
 
 expression     = identifier
                | identifier ':' expression
                | call
                | call ':' expression
 
 call           = primary argument*
 
 primary        = boolean
                | number
                | string
                | identifier
                | '(' expression ')'
 
 argument       = ( '(' parameters? ')' | '[' identifier ']' )
 parameters     = expression ( "," expression )* ;

 expression     = identifier
                | identifier ':' expression
                | call '[' identifier ']'
                | call '[' identifier ']' ':' expression
 
 call           = primary argument*
 
 primary        = boolean
                | number
                | string
                | identifier
                | '(' expression ')'
 
 argument       = ( '(' parameters? ')' | '[' identifier ']' )
 parameters     = expression ( "," expression )* ;

 -------TODO--------

 or             = and ( '|' and )*
 and            = equality ( '&' equality )*
 equality       = comparison ( '=' comparison )*
 comparison     = arithmetic ( ( ">" | "<" ) arithmetic )*
 arithmetic     = multiplicative ( ( "-" | "+" ) multiplicative )*
 multiplicative = prefix ( ( "/" | "*" ) prefix )*
 prefix         = ( "!" | "-" ) prefix | call
 
 boolean        = 'true' | 'false'
 number         = digit+ ( '.' digit* )? | '.' digit+
 string         = '"' <not eol and not '"'>* '"'
 identifier     = alpha ( alpha | digit )*
 alpha          = 'a' ... 'z' | 'A' ... 'Z' | '_'
 digit          = '0' ... '9'
 eol            = '\n'
 eos            = <end of stream token>

 -------------------

 record         = '{' keywords? '}'
 keywords       = identifier ':' expression ( ',' identifier ':' expression )*
 
 list           = '[' elements? ']'
 elements       = expression ( ',' expression )*
 
 function       = '(' parameters? ')' '{' expression* '}'
 parameters     = identifier ( ',' identifier )*
 
 -------------------
 
    TODO: super.

    program    = declaration* eof ;

    declaration = classDecl
                | funDecl
                | varDecl
                | statement ;

    statement   = exprStmt
                | forStmt
                | ifStmt
                | returnStmt
                | whileStmt
                | block ;

    classDecl   = "class" identifier ( "<" identifier )? "{" function* "}" ;
    funDecl     = "fun" function ;
    varDecl     = "var" identifier ( "=" expression )? ";" ;

    exprStmt    = expression ";" ;
    forStmt     = "for" "(" ( varDecl | exprStmt ) expression? ";" expression? ")"
                  statement ;
    ifStmt      = "if" "(" expression ")" statement ( "else" statement )? ;
    returnStmt  = "return" expression? ";" ;
    whileStmt   = "while" "(" expression ")" statement ;

    block       = "{" declaration* "}" ;
    function    = identifier "(" parameters? ")" block ;
    parameters  = identifier ( "," identifier )* ;

    expression  = assignment ;
    assignment  = ( call "." )? identifier ( "=" assignment )? ;
    or          = and ( "or" and )* ;
    and         = equality ( "and" equality )* ;
    equality    = comparison ( ( "!=" | "==" ) comparison )* ;
    comparison  = term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
    term        = factor ( ( "-" | "+" ) factor )* ;
    factor      = unary ( ( "/" | "*" ) unary )* ;
    unary       = ( "!" | "-" ) unary | call ;
    call        = primary ( "(" arguments? ")" | "." identifier )* ;
    primary     = "true" | "false" | "null" | "this"
                | number | string | identifier | "(" expression ")" ;

    arguments   = expression ( "," expression )* ;

    number      = digit+ ( "." digit* )? | "." digit+ ;
    string      = '"' <any char except '"'>* '"' ;
    identifier  = alpha ( alpha | digit )* ;
    alpha       = 'a' ... 'z' | 'A' ... 'Z' | '_' ;
    digit       = '0' ... '9' ;
    eof         = <special token indicating end of input>
 
 **/

import Foundation

public final class Parser {
    
    public enum Error: Swift.Error {
        case unsupportedExpression(Token)
        case unsupportedPrimary(Token)
        
        case unrecognizedBooleanLiteral(Token.Location, Bool)
        case unrecognizedNumberLiteral(Token.Location, Double)
        case unrecognizedStringLiteral(Token.Location, String)
        case unrecognizedVariable(Token.Location, String)
        
        case unexpectedGroupOpen(Token, Token.Lexeme)
        case unexpectedGroupClose(Token, Token.Lexeme)

        case unexpectedListOpen(Token, Token.Lexeme)
        case unexpectedListNext(Token, Token.Lexeme)
        case unexpectedListClose(Token, Token.Lexeme)

        case unexpectedBinaryOperator(Token, Token.Lexeme)
        case unexpectedUnaryOperator(Token, Token.Lexeme)

        public var location: Token.Location {
            switch self {
            case .unsupportedExpression(let token):
                return token.location
            case .unsupportedPrimary(let token):
                return token.location
            case .unrecognizedBooleanLiteral(let value, _):
                return value
            case .unrecognizedNumberLiteral(let value, _):
                return value
            case .unrecognizedStringLiteral(let value, _):
                return value
            case .unrecognizedVariable(let value, _):
                return value
            case .unexpectedGroupOpen(let token, _):
                return token.location
            case .unexpectedGroupClose(let token, _):
                return token.location
            case .unexpectedListOpen(let token, _):
                return token.location
            case .unexpectedListNext(let token, _):
                return token.location
            case .unexpectedListClose(let token, _):
                return token.location
            case .unexpectedBinaryOperator(let token, _):
                return token.location
            case .unexpectedUnaryOperator(let token, _):
                return token.location
            }
        }

//        public var expressions: [AST.Expression] {
//            switch self {
//            case .unexpectedToken(_, _, let value, _):
//                return value
//            }
//        }
        
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
        return current.lexeme.isEqual(to:lexeme, withStrictEquality:true)
    }

    //    public enum Grammar {
    //        case boolean
    //        case number
    //        case string
    //        case variable
    //        case group
    //        case list
    //        case primary
    //        case binary
    //        case unary
    //        case expression
    //    }

    //    private func consume(_ lexeme: Token.Lexeme, grammar: Grammar) throws -> Token {
    //        if !isFinished && check(lexeme) {
    //            return advance()
    //        }
    //        throw Error.unexpectedToken(current, grammar, expressions, lexeme)
    //    }

    private func consume(_ lexeme: Token.Lexeme, or error: Parser.Error) throws -> Token {
        if !isFinished && check(lexeme) {
            return advance()
        }
        throw error
    }
    
    public func parse() throws -> [AST.Expression] {
        reset()
        while !isFinished {
            switch current.lexeme {
            /// Blank lines
            case .eol:
                let _ = try consume(.eol, or:.unsupportedExpression(current))
            /// Comments
            case .hash(let value):
                let _ = try consume(.hash(value), or:.unsupportedExpression(current))
            /// Everything else
            default:
                expressions.append(try parseExpression())
                let _ = try consume(.eol, or:.unsupportedExpression(current))
            }
        }
        return expressions
    }
    
    private func parseBoolean(_ value: Bool) throws -> AST.Expression {
        let _ = try consume(.boolean(value), or:.unrecognizedBooleanLiteral(current.location, value))
        return .boolean(value)
    }
    
    private func parseNumber(_ value: Double) throws -> AST.Expression {
        let _ = try consume(.number(value), or:.unrecognizedNumberLiteral(current.location, value))
        return .number(value)
    }
    
    private func parseString(_ value: String) throws -> AST.Expression {
        let _ = try consume(.string(value), or:.unrecognizedStringLiteral(current.location, value))
        return .string(value)
    }

    private func parseVariable(_ value: AST.Identifier) throws -> AST.Expression {
        let _ = try consume(.identifier(value), or:.unrecognizedVariable(current.location, value))
        return .variable(value)
    }

    private func parseGroup(_ open: Token.Lexeme, _ close: Token.Lexeme) throws -> AST.Expression {
        let _ = try consume(open, or:.unexpectedGroupOpen(current, open))
        let result = try parseExpression()
        let _ = try consume(close, or:.unexpectedGroupClose(current, close))
        return result
    }

    private func parseList(_ open: Token.Lexeme, _ separator: Token.Lexeme, _ close: Token.Lexeme) throws -> AST.Expression {
        let _ = try consume(open, or:.unexpectedListOpen(current, open))
        var elements: [AST.Expression] = []
        while !check(close) {
            elements.append(try parseExpression())
            if check(separator) {
                let _ = try consume(separator, or:.unexpectedListNext(current, separator))
            }
        }
        let _ = try consume(close, or:.unexpectedListClose(current, close))
        return .list(elements)
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
            return try parseGroup(.parenLeft, .parenRight)
        case .squareLeft:
            return try parseList(.squareLeft, .comma, .squareRight)
        default:
            throw Error.unsupportedPrimary(current)
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
                rhs = try parseGroup(.squareLeft, .squareRight)
            case .call:
                rhs = try parseList(.parenLeft, .comma, .parenRight)
            default:
                let _ = try consume(binary.lexeme, or:.unexpectedBinaryOperator(current, binary.lexeme))
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
    
    private func parseUnaryOperator() throws -> AST.Expression {
        guard let unary = AST.UnaryOperator(current.lexeme) else {
            return try parsePrimary()
        }
        let _ = try consume(unary.lexeme, or:.unexpectedUnaryOperator(current, unary.lexeme))
        return .unary(unary, try parseUnaryOperator())
    }
    
    private func reset() {
        expressions.removeAll(keepingCapacity:true)
        currentIndex = tokens.startIndex
    }
    
    private var current: Token {
        return tokens[currentIndex]
    }
    
    private var isFinished: Bool {
        return current.lexeme.isEqual(to:.eos, withStrictEquality:true)
    }

    private let tokens: [Token]
    private var expressions: [AST.Expression]
    private var currentIndex: Int
}

extension Parser.Error: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .unsupportedExpression(let token):
            return "An unsupported expression was encountered beginning with: '\(token.lexeme)'"
        case .unsupportedPrimary(let token):
            return "An unsupported primary expression was encountered beginning with: '\(token.lexeme)'"
            
        case .unrecognizedBooleanLiteral(_, let value):
            return "Failed to recognize the boolean literal expression: '\(value)'"
        case .unrecognizedNumberLiteral(_, let value):
            return "Failed to recognize the number literal expression: '\(value)'"
        case .unrecognizedStringLiteral(_, let value):
            return "Failed to recognize the string literal expression: '\(value)'"
        case .unrecognizedVariable(_, let value):
            return "Failed to recognize the variable expression: '\(value)'"
            
        case .unexpectedGroupOpen(let token, let expected):
            return "Expected '\(expected)' when opening a group expression but received: '\(token.lexeme)'"
        case .unexpectedGroupClose(let token, let expected):
            return "Expected '\(expected)' when closing a group expression but received: '\(token.lexeme)'"

        case .unexpectedListOpen(let token, let expected):
            return "Expected '\(expected)' when opening a list expression but received: '\(token.lexeme)'"
        case .unexpectedListNext(let token, let expected):
            return "Expected '\(expected)' when extending a list expression but received: '\(token.lexeme)'"
        case .unexpectedListClose(let token, let expected):
            return "Expected '\(expected)' when closing a list expression but received: '\(token.lexeme)'"
            
        case .unexpectedBinaryOperator(let token, let expected):
            return "Expected '\(expected)' when forming a binary expression but received: '\(token.lexeme)'"
        case .unexpectedUnaryOperator(let token, let expected):
            return "Expected '\(expected)' when forming a unary expression but received: '\(token.lexeme)'"
        }
    }
}
