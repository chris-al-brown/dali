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

public final class Dali {

    public enum ANSIColor: String {
        case black      = "\u{001B}[0;30m"
        case red        = "\u{001B}[0;31m"
        case green      = "\u{001B}[0;32m"
        case yellow     = "\u{001B}[0;33m"
        case blue       = "\u{001B}[0;34m"
        case magenta    = "\u{001B}[0;35m"
        case cyan       = "\u{001B}[0;36m"
        case white      = "\u{001B}[0;37m"

        public func apply(_ item: Any) -> String {
            return "\(rawValue)\(item)\u{001B}[0;0m"
        }
    }

    /// Checks whether Xcode spawned the process (i.e. ANSI color codes not supported)
    public enum Environment: CustomStringConvertible {
        case terminal
        case xcode
        
        public init() {
            let environment = ProcessInfo.processInfo.environment
            let xcode = environment["XPC_SERVICE_NAME"]?.range(of:"Xcode") != nil
            self = xcode ? .xcode : .terminal
        }
        
        public var description: String {
            switch self {
            case .terminal:
                return "iterm"
            case .xcode:
                return "xcode"
            }
        }
    }
    
    public enum Input: CustomStringConvertible {
        case file(String)
        case stdin
        case usage
        
        public var description: String {
            switch self {
            case .file(let value):
                return "file: '\(value)'"
            case .stdin:
                return "<stdin>"
            case .usage:
                return "dali <script>"
            }
        }
    }

    public enum Status {
        case success
        case failure
    }
    
    public init(_ args: [String], env: Environment = Environment()) {
        self.env = env
        if args.count == 1 {
            self.input = .stdin
        } else if args.count == 2 {
            self.input = .file(args[1])
        } else {
            self.input = .usage
        }
    }
    
    public func compile(_ source: Source) {
        do {
            let scanner = Scanner(source)
            let tokens = try scanner.scan()
            do {
                let parser = Parser(tokens)
                let expressions = try parser.parse()
                for expression in expressions {
                    print(format(expression))
                }
            } catch let issue as Parser.Error {
                error(issue, in:source)
            } catch let other {
                fatalError("Expected a ParserError: \(other)")
            }
        } catch let issue as Scanner.Error {
            error(issue, in:source)
        } catch let other {
            fatalError("Expected a ScannerError: \(other)")
        }
    }
    
    private func error(_ message: String) {
        print(message, color:.red)
    }
    
    private func error(_ issue: Parser.Error, in source: Source) {
        print(format(issue, in:source))
    }
    
    private func error(_ issue: Scanner.Error, in source: Source) {
        print(format(issue, in:source))
    }

    public func exit(with status: Status) -> Never {
        switch status {
        case .success:
            Darwin.exit(EXIT_SUCCESS)
        case .failure:
            Darwin.exit(EXIT_FAILURE)
        }
    }

    private func format(_ value: AST.Expression) -> String {
        switch value {
        case .assign(let key, let value):
            var output = ""
            output += useColor ? ANSIColor.cyan.apply(key) : key
            output += ":"
            output += " "
            output += format(value)
            return output
        case .binary(let lhs, let op, let rhs):
            var output = ""
            output += "("
            output += format(lhs)
            output += " "
            output += useColor ? ANSIColor.green.apply(op.lexeme.description) : op.lexeme.description
            output += " "
            output += format(rhs)
            output += ")"
            return output
        case .call(let lhs, let args):
            var output = ""
            output += format(lhs)
            output += "("
            output += args.reduce("") {
                let key = $0.1.0
                let value = format($0.1.1)
                return $0.0 + key + ": " + value + ", "
            }
            if !args.isEmpty {
                let _ = output.unicodeScalars.popLast()
                let _ = output.unicodeScalars.popLast()
            }
            output += ")"
            return output
        case .get(let lhs, let index):
            var output = ""
            output += format(lhs)
            output += "["
            output += format(index)
            output += "]"
            return output
        case .primary(let primary):
            return format(primary)
        case .set(let lhs, let index, let rhs):
            var output = ""
            output += format(lhs)
            output += "["
            output += format(index)
            output += "]"
            output += ":"
            output += " "
            output += format(rhs)
            return output
        case .unary(let op, let rhs):
            var output = ""
            output += "("
            output += useColor ? ANSIColor.green.apply(op.lexeme.description) : op.lexeme.description
            output += format(rhs)
            output += ")"
            return output
        }
    }
    
    private func format(_ value: AST.Primary) -> String {
        switch value {
        case .boolean(let value):
            return useColor ? ANSIColor.yellow.apply(value.description) : value.description
        case .function(let args, let body):
            var output = ""
            output += useColor ? ANSIColor.green.apply("@") : "@"
            output += "("
            output += args.reduce("") {
                return $0.0 + $0.1 + ", "
            }
            if !args.isEmpty {
                let _ = output.unicodeScalars.popLast()
                let _ = output.unicodeScalars.popLast()
            }
            output += "){"
            output += body.reduce("") {
                return $0.0 + format($0.1) + ", "
            }
            if !body.isEmpty {
                let _ = output.unicodeScalars.popLast()
                let _ = output.unicodeScalars.popLast()
            }
            output += "}"
            return output
        case .identifier(let value):
            return useColor ? ANSIColor.cyan.apply(value) : value
        case .keyword(let value):
            return useColor ? ANSIColor.yellow.apply(value.rawValue) : value.rawValue
        case .list(let values):
            var output = ""
            output += "["
            output += values.reduce("") {
                return $0.0 + format($0.1) + ", "
            }
            if !values.isEmpty {
                let _ = output.unicodeScalars.popLast()
                let _ = output.unicodeScalars.popLast()
            }
            output += "]"
            return output
        case .map(let values):
            var output = ""
            output += "{"
            output += values.reduce("") {
                let key = $0.1.0
                let value = format($0.1.1)
                return $0.0 + key + ": " + value + ", "
            }
            if !values.isEmpty {
                let _ = output.unicodeScalars.popLast()
                let _ = output.unicodeScalars.popLast()
            }
            output += "}"
            return output
        case .number(let value):
            return useColor ? ANSIColor.blue.apply(value.description) : value.description
        case .string(let value):
            return useColor ? ANSIColor.magenta.apply("\"" + value + "\"") : "\"" + value + "\""
        }
    }
    
    private func format(_ issue: Parser.Error, in source: Source) -> String {
        return format(issue.description, in:source, at:issue.location)
    }

    private func format(_ issue: Scanner.Error, in source: Source) -> String {
        return format(issue.description, in:source, at:issue.location)
    }
    
    private func format(_ message: String, in source: Source, at location: Source.Location) -> String {
        let row = source.line(for:location)
        let col = source.columns(for:location)
        var output = ""
        output += "file: \(input), line: \(row), "
        output += (col.count == 1) ? "column: \(col.lowerBound)\n" : "columns: \(col.lowerBound)-\(col.upperBound)\n"
        output += source.extractLine(location) + "\n"
        output += String(repeating:" ", count:col.lowerBound - 1) + String(repeating:"^", count:col.count) + "\n"
        output += "SyntaxError: \(message)"
        return useColor ? ANSIColor.red.apply(output) : output
    }
    
    private func print(_ message: String, color: ANSIColor? = nil, terminator: String = "\n") {
        if let kuler = color, useColor {
            Swift.print(kuler.apply(message), separator:"", terminator:terminator)
        } else {
            Swift.print(message, separator:"", terminator:terminator)
        }
    }
    
    public func run() -> Never {
        switch input {
        case .file(let name):
            do {
                let source = Source(try String(contentsOfFile:name, encoding:.utf8))
                compile(source)
                exit(with:.success)
            } catch let issue {
                error("ScriptError: \(issue.localizedDescription)")
                exit(with:.failure)
            }
        case .stdin:
            print("-------------------------------------")
            print(" dali REPL v0.1.0 (press ^C to exit) ")
            print("-------------------------------------")
            var buffer = ""
            while true {
                print(">>>", terminator:" ")
                while true {
                    guard let line = readLine(strippingNewline:false) else { break }
                    buffer += line
                    let source = Source(buffer)
                    if source.needsContinuation {
                        print("...", terminator:" ")
                    } else {
                        compile(source)
                        buffer.removeAll(keepingCapacity:true)
                        break
                    }
                }
            }
        case .usage:
            print("Usage: \(input)")
            exit(with:.success)
        }
    }
    
    private var useColor: Bool {
        return env == .terminal
    }
    
    private let env: Environment
    private let input: Input
}
