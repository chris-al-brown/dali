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
// Console.swift
// 02/23/2017
// Pretty formatting of expressions and errors
// -----------------------------------------------------------------------------

import Foundation

public struct Console {
    
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
        
        public var supportsColor: Bool {
            return self == .terminal
        }
    }
    
    public struct Formatter: ExpressionVisitor {
        
        public init(useColor: Bool) {
            self.useColor = useColor
        }
        
        public func visit(_ expression: Expression) -> String {
            switch expression.symbol {
            case .assign(let key, let value):
                var output = ""
                output += useColor ? ANSIColor.cyan.apply(key) : key
                output += ":"
                output += " "
                output += visit(value)
                return output
            case .binary(let lhs, let op, let rhs):
                var output = ""
                output += "("
                output += visit(lhs)
                output += " "
                output += useColor ? ANSIColor.green.apply(op.lexeme.description) : op.lexeme.description
                output += " "
                output += visit(rhs)
                output += ")"
                return output
            case .boolean(let value):
                return useColor ? ANSIColor.yellow.apply(value.description) : value.description
            case .call(let lhs, let args):
                var output = ""
                output += "("
                output += visit(lhs)
                output += ")"
                output += "("
                output += args.reduce("") {
                    let key = useColor ? ANSIColor.cyan.apply($0.1.0) : $0.1.0
                    let value = visit($0.1.1)
                    return $0.0 + key + ": " + value + ", "
                }
                if !args.isEmpty {
                    let _ = output.unicodeScalars.popLast()
                    let _ = output.unicodeScalars.popLast()
                }
                output += ")"
                return output
            case .function(let args, let body):
                var output = ""
                output += useColor ? ANSIColor.green.apply("@") : "@"
                output += "("
                output += args.reduce("") {
                    let arg = useColor ? ANSIColor.cyan.apply($0.1) : $0.1
                    return $0.0 + arg + ", "
                }
                if !args.isEmpty {
                    let _ = output.unicodeScalars.popLast()
                    let _ = output.unicodeScalars.popLast()
                }
                output += ") {"
                output += body.reduce("") {
                    return $0.0 + visit($0.1) + ", "
                }
                if !body.isEmpty {
                    let _ = output.unicodeScalars.popLast()
                    let _ = output.unicodeScalars.popLast()
                }
                output += "}"
                return output
            case .get(let lhs, let index):
                var output = ""
                output += visit(lhs)
                output += "["
                output += visit(index)
                output += "]"
                return output
            case .keyword(let value):
                return useColor ? ANSIColor.yellow.apply(value.rawValue) : value.rawValue
            case .list(let values):
                var output = ""
                output += "["
                output += values.reduce("") {
                    return $0.0 + visit($0.1) + ", "
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
                    let key = useColor ? ANSIColor.cyan.apply($0.1.0) : $0.1.0
                    let value = visit($0.1.1)
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
            case .set(let lhs, let index, let rhs):
                var output = ""
                output += visit(lhs)
                output += "["
                output += visit(index)
                output += "]"
                output += ":"
                output += " "
                output += visit(rhs)
                return output
            case .string(let value):
                return useColor ? ANSIColor.magenta.apply("\"" + value + "\"") : "\"" + value + "\""
            case .unary(let op, let rhs):
                var output = ""
                output += "("
                output += useColor ? ANSIColor.green.apply(op.lexeme.description) : op.lexeme.description
                output += visit(rhs)
                output += ")"
                return output
            case .variable(let value):
                return useColor ? ANSIColor.cyan.apply(value) : value
            }
        }
        
        public var useColor: Bool
    }
    
    public init() {
        self.environment = Environment()
        self.formatter = Formatter(useColor:environment.supportsColor)
    }
    
    public func error(_ message: String, terminator: String = "\n") {
        if formatter.useColor {
            print(ANSIColor.red.apply(message), separator:"", terminator:terminator)
        } else {
            print(message, separator:"", terminator:terminator)
        }
    }
    
    public func error(_ issue: Parser.Error, in source: Source) {
        error(format(issue.description, in:source, at:issue.location))
    }
    
    public func error(_ issue: Scanner.Error, in source: Source) {
        error(format(issue.description, in:source, at:issue.location))
    }
    
    public func error(_ issue: Validator.Error, in source: Source) {
        error(format(issue.description, in:source, at:issue.location))
    }

    private func format(_ message: String, in source: Source, at location: Source.Location) -> String {
        let row = source.line(for:location)
        let col = source.columns(for:location)
        var output = ""
        output += "file: \(source.input), line: \(row), "
        output += (col.count == 1) ? "column: \(col.lowerBound)\n" : "columns: \(col.lowerBound)-\(col.upperBound)\n"
        output += source.extractLine(location) + "\n"
        output += String(repeating:" ", count:col.lowerBound - 1) + String(repeating:"^", count:col.count) + "\n"
        output += message
        return output
    }
    
    public func log(_ message: String, terminator: String = "\n") {
        print(message, separator:"", terminator:terminator)
    }
    
    public func log(_ expression: Expression) {
        print(formatter.visit(expression))
    }
    
    public func prompt(isContinuation: Bool = false) {
        if isContinuation {
            print("...", separator:"", terminator:" ")
        } else {
            print(">>>", separator:"", terminator:" ")
        }
    }
    
    private var environment: Environment
    private var formatter: Formatter
}

