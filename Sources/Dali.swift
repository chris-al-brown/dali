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
    
    public enum Status {
        case success
        case failure
    }
    
    /// Compile a program from a source string
    public static func compile(_ source: Source) {
        let scanner = Scanner(source)
        do {
            let tokens = try scanner.scan()
            do {
                let parser = Parser(tokens)
                let expressions = try parser.parse()
                for expression in expressions {
                    log(pretty(expression))
                }
            } catch let issue as Parser.Error {
                error(source, tokens, issue)
            } catch _ {
                fatalError("0xdeadbeef")
            }
        } catch let issue as Scanner.Error {
            error(source, issue)
        } catch _ {
            fatalError("0xdeadbeef")
        }
    }
    
    public static func error(_ string: String, terminator: String = "\n") {
        print(string, separator:"", terminator:terminator)
    }

    public static func error(_ source: Source, _ issue: Scanner.Error) {
        error(source.format(error:"SyntaxError: \(issue.description)", at:issue.location))
    }
    
    public static func error(_ source: Source, _ tokens: [Token], _ issue: Parser.Error) {
        error(source.format(error:"SyntaxError: \(issue.description)", using:tokens, at:issue.location))
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
    
    
    /// DEBUG
    
    public static func pretty(_ expression: AST.Expression) -> String {
        return "\(expression)"
        
//        switch expression {
//        case .binary(let lhs, let op, let rhs):
//            switch op {
//            case .get:
//                return "\(pretty(lhs))[\(pretty(rhs))]"
//            case .call:
//                return "\(pretty(lhs))(\(pretty(rhs)))"
//            default:
//                return "(\(op.lexeme) \(pretty(lhs)) \(pretty(rhs)))"
//            }
//        case .boolean(let value):
//            return value.description
//        case .function(_, _):
//            return ""
//        case .list(_):
//            return ""
//        case .map(_):
//            return ""
//        case .number(let value):
//            return value.description
//        case .string(let value):
//            return value
//        case .unary(let op, let rhs):
//            return "(\(op.lexeme) \(pretty(rhs))"
//        case .variable(let value):
//            return value
//        }
        
    }
    
    /// DEBUG
    
    /// Read-Eval-Print Loop
    public static func repl(supportsColor: Bool) -> Never {
        log("-------------------------------------")
        log(" dali REPL v0.1.0 (press ^C to exit) ")
        log("-------------------------------------")
        var lines = ""
        while true {
            log(">>>", terminator:" ")
            while true {
                guard let line = readLine(strippingNewline:false) else { break }
                lines += line
                let source = Source(input:.stdin, source:lines, supportsColor:supportsColor)
                if source.checkParentheses() {
                    compile(source)
                    lines.removeAll(keepingCapacity:true)
                    break
                } else {
                    log("...", terminator:" ")
                }
            }
        }
    }
    
    /// Run a script
    public static func script(_ name: String, supportsColor: Bool) {
        do {
            let source = try String(contentsOfFile:name, encoding:.utf8)
            compile(Source(input:.file(name), source:source, supportsColor:supportsColor))
            exit(with:.success)
        } catch let issue {
            error("ScriptError: \(issue.localizedDescription)")
            exit(with:.failure)
        }
    }
    
    /// Print the usage and exit
    public static func usage() {
        log("Usage: dali <script>")
        exit(with:.success)
    }
}
