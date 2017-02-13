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
 
 x
 x: 10
 x: circle()[x]
 geometry[circle][x]: 10
 geometry[circle](0, 0, 1)
 default_circle()[x]: other_circle()[x]

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
        case unexpectedToken(Token, Token.Lexeme)
    }
    
    public enum Result {
        case success([AST.Statement])
        case failure([Error])
    }
 
    public init(tokens: [Token]) {
        self.tokens = tokens
        self.statements = []
        self.errors = []
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

    private func consume(_ lexeme: Token.Lexeme) -> Token? {
        if isFinished { return nil }
        if check(lexeme) {
            return advance()
        }
        
        /// ERROR: Reading characters until hit character or end of stream
        errors.append(.unexpectedToken(current, lexeme))
        
        while !check(lexeme) && !isFinished {
            let _ = advance()
        }
        
        return advance()
    }
    
    public func parse() -> Result {
        reset()
        while !isFinished {
            switch current.lexeme {
            case .eol:
                let _ = consume(.eol)
            default:
                if let statement = parseStatement() {
                    statements.append(statement)
                }
            }
        }
        return errors.isEmpty ? .success(statements) : .failure(errors)
    }
    
    private func parseBoolean(_ value: Bool) -> AST.Expression {
        let _ = consume(.boolean(value))
        return .boolean(value)
    }
    
    private func parseNumber(_ value: Double) -> AST.Expression {
        let _ = consume(.number(value))
        return .number(value)
    }
    
    private func parseString(_ value: String) -> AST.Expression {
        let _ = consume(.string(value))
        return .string(value)
    }

    private func parseIdentifier(_ value: AST.Identifier) -> AST.Expression? {
        let _ = consume(.identifier(value))
        if check(.parenLeft) {
            let _ = consume(.parenLeft)
            var args: [AST.Expression] = []
            while !check(.parenRight) {
                if let expression = parseExpression() {
                    args.append(expression)
                } else {
                    return nil
                }
                if check(.comma) {
                    let _ = consume(.comma)
                } else {
                    break
                }
            }
            let _ = consume(.parenRight)
            return .call(value, args)
        }
        if check(.squareLeft) {
            let _ = consume(.squareLeft)
            guard let result = parseExpression() else {
                return nil
            }
            let _ = consume(.squareRight)
            return .access(value, result)
        }
        return .identifier(value)
    }
    
    private func parseGroup() -> AST.Expression? {
        let _ = consume(.parenLeft)
        guard let result = parseExpression() else { return nil }
        let _ = consume(.parenRight)
        return result
    }
    
    /// TODO:
    /// - Add parsing of [...](...)[...](...) expressions
    /// - Clean up binary operator parsing
    /// - Add unary operator parsing
    /// - Parsing function prototypes
    /// - Add token locations to the expressions for errors, etc.
    
    private func parseBinaryOperator(_ lhs: AST.Expression, _ precedence: Int = 0) -> AST.Expression? {
        var lhs = lhs
        while true {
            guard let binary = AST.BinaryOperator(current.lexeme) else {
                return lhs
            }
            if binary.precedence < precedence {
                return lhs
            }
            let _ = consume(binary.lexeme)
            var rhs = parsePrimary()
            if rhs == nil { return nil }
            let nextBinary = AST.BinaryOperator(current.lexeme)
            let nextPrecedence = nextBinary?.precedence ?? -1
            if precedence < nextPrecedence {
                rhs = parseBinaryOperator(rhs!, precedence + 1)
                if rhs == nil {
                    return nil
                }
            }
            lhs = .binary(lhs, binary, rhs!)
        }
    }
    
//    private func parseUnaryOperator(_ precedence: Int = 0) -> AST.Expression? {
//        return nil
//    }
    
    private func parseExpression() -> AST.Expression? {
        guard let result = parsePrimary() else { return nil }
        return parseBinaryOperator(result)
    }
    
    private func parsePrimary() -> AST.Expression? {
        switch current.lexeme {
        case .boolean(let value):
            return parseBoolean(value)
        case .number(let value):
            return parseNumber(value)
        case .identifier(let value):
            return parseIdentifier(value)
        case .string(let value):
            return parseString(value)
        case .parenLeft:
            return parseGroup()
        default:
            /// ERROR: Failed to parse primary
            return nil
        }
    }
    
    private func parseStatement() -> AST.Statement? {
        guard let result = parseExpression() else { return nil }
        let _ = consume(.eol)
        return result
    }

    private func reset() {
        self.statements = []
        self.errors = []
        self.currentIndex = tokens.startIndex
    }
    
    private var current: Token {
        return tokens[currentIndex]
    }
    
    private var isFinished: Bool {
        return current.lexeme.isEqual(to:.eos, withStrictEquality:true)
    }

    private let tokens: [Token]
    private var statements: [AST.Statement]
    private var errors: [Error]
    private var currentIndex: Int
}

extension Parser.Error: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .unexpectedToken(let token, let expected):
            return "\(token.location) ERROR: Expected '\(expected)' but instead received: '\(token.lexeme)'"
        }
    }
}
