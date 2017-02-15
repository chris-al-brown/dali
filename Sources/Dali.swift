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
// Dali.swift
// 02/10/2017
// Represents an instance of a running program or script
// -----------------------------------------------------------------------------

import Foundation

public struct Dali {
    
    /// Terminal colors
    public enum Color: String {
        case black      = "\u{001B}[0;30m"
        case red        = "\u{001B}[0;31m"
        case green      = "\u{001B}[0;32m"
        case yellow     = "\u{001B}[0;33m"
        case blue       = "\u{001B}[0;34m"
        case magenta    = "\u{001B}[0;35m"
        case cyan       = "\u{001B}[0;36m"
        case white      = "\u{001B}[0;37m"
        
        public func apply(_ item: Any) -> String {
            switch Dali.launchEnv {
            case .terminal:
                return "\(rawValue)\(item)\u{001B}[0;0m"
            case .xcode:
                return "\(item)"
            }
        }
    }
    
    /// Launch envionment
    public enum Environment {
        case terminal
        case xcode
        
        public init() {
            let env = ProcessInfo.processInfo.environment
            if let value = env["XPC_SERVICE_NAME"] {
                self = value.range(of:"Xcode") != nil ? .xcode : .terminal
            } else {
                self = .terminal
            }
        }
    }

    public enum Status {
        case success
        case failure
    }

    public static var launchEnv: Environment = Environment()
    
    /// Compile a program from a source string
    public static func compile(_ source: Source) {
        do {
            let scanner = Scanner(source)
            let tokens = try scanner.scan()
            let parser = Parser(tokens)
            let expressions = try parser.parse()
            for expression in expressions {
                print(expression)
            }
        } catch let err as Scanner.Error {
            error(source, err)
        } catch let err as Parser.Error {
            error(source, err)
        } catch _ {
            fatalError()
        }
    }
    
    public static func error(_ string: String, terminator: String = "\n") {
        print(Color.red.apply(string), separator:"", terminator:terminator)
    }

    public static func error(_ source: Source, _ issue: Parser.Error) {
        error(source.format(error:"SyntaxError: \(issue.description)", for:issue.location))
    }
    
    public static func error(_ source: Source, _ issue: Scanner.Error) {
        error(source.format(error:"SyntaxError: \(issue.description)", for:issue.location))
    }
    
    public static func exit(with status: Status) -> Never {
        switch status {
        case .success:
            Darwin.exit(EXIT_SUCCESS)
        case .failure:
            Darwin.exit(EXIT_FAILURE)
        }
    }

    public static func log(_ string: String, terminator: String = "\n") {
        print(string, separator:"", terminator:terminator)
    }
    
    public static func log(_ string: String, color: Color, terminator: String = "\n") {
        print(color.apply(string), separator:"", terminator:terminator)
    }

//    public static func log(_ tokens: [Token], terminator: String = "\n") {
//        for token in tokens {
//            let lexeme = token.lexeme
//            switch lexeme {
//            /// Punctuation
//            case .comma, .curlyLeft, .curlyRight, .parenLeft, .parenRight, .squareLeft, .squareRight:
//                log(lexeme.description, terminator:" ")
//
//            /// Operators
//            case .colon, .plus, .minus, .star, .slash, .equal, .carrotLeft, .carrotRight, .exclamation, .ampersand, .bar:
//                log(lexeme.description, color:.green, terminator:" ")
//                
//            /// Hash
//            case .hash:
//                log(lexeme.description, color:.black, terminator:" ")
//                
//            /// Literals
//            case .boolean(_):
//                log(lexeme.description, color:.yellow, terminator:" ")
//                
//            case .number(_):
//                log(lexeme.description, color:.blue, terminator:" ")
//                
//            case .string(_):
//                log(lexeme.description, color:.magenta, terminator:" ")
//                
//            /// Identifiers & Keywords
//            case .identifier(_):
//                log(lexeme.description, color:.cyan, terminator:" ")
//                
//            /// Newlines
//            case .eol:
//                log(lexeme.description, color:.black)
//            }
//        }
//        log("", terminator:terminator)
//    }
    
    /// Read-Eval-Print Loop
    public static func repl() -> Never {
        log("-------------------------------------")
        log(" dali REPL v0.1.0 (press ^C to exit) ")
        log("-------------------------------------")
        while true {
            log(">>>", terminator:" ")
            guard let input = readLine(strippingNewline:false) else { continue }
            compile(Source(.stdin, input))
        }
    }
    
    /// Run a script
    public static func script(_ name: String) {
        do {
            compile(Source(.file(name), try String(contentsOfFile:name, encoding:.utf8)))
            exit(with:.success)
        } catch let err {
            error("ScriptError: \(err.localizedDescription)")
            exit(with:.failure)
        }
    }
    
    /// Print the usage and exit
    public static func usage() {
        log("Usage: dali <script>")
        exit(with:.success)
    }
}
