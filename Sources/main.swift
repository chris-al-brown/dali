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
// main.swift
// 01/20/2017
// Main entry point for the command line tool
// -----------------------------------------------------------------------------

import Foundation

public final class Dali {
    
    public enum Mode {
        case file(String)
        case help
        case repl
    }
    
    public enum Status {
        case success
        case failure
    }
    
    public init(_ args: [String]) {
        self.interpreter = Interpreter()
        let environment = ProcessInfo.processInfo.environment
        self.iterm = environment["XPC_SERVICE_NAME"]?.range(of:"Xcode") == nil
        switch args.count {
        case 1:
            self.mode = .repl
        case 2:
            switch args[1] {
            case "-h", "--help":
                self.mode = .help
            default:
                self.mode = .file(args[1])
            }
        default:
            self.mode = .help
        }
    }
    
    public func compile(_ source: Source) -> Status {
        do {
            let scanner = Scanner(source)
            let parser = Parser(try scanner.scan())
            let objects = try interpreter.interpret(try parser.parse())
            objects.forEach {
                if let object = $0 {
                    log(object)
                }
            }
            return .success
        } catch let issue as Interpreter.Error {
            error(issue, in:source)
        } catch let issue as Scanner.Error {
            error(issue, in:source)
        } catch let issue as Parser.Error {
            error(issue, in:source)
        } catch {
            fatalError("Unexpected error: \(error)")
        }
        return .failure
    }
    
    public func error(_ message: String, separator: String = "", terminator: String = "\n") {
        if iterm {
            print("\u{001B}[0;31m\(message)\u{001B}[0;0m", separator:separator, terminator:terminator)
        } else {
            print(message, separator:separator, terminator:terminator)
        }
    }
    
    private func error(_ message: String, in source: Source, at location: Source.Location) {
        let row = source.line(for:location)
        let col = source.columns(for:location)
        var output = ""
        output += "file: \(source.input), line: \(row), "
        output += (col.count == 1) ? "column: \(col.lowerBound)\n" : "columns: \(col.lowerBound)-\(col.upperBound)\n"
        output += source.extractLine(location) + "\n"
        output += String(repeating:" ", count:col.lowerBound - 1) + String(repeating:"^", count:col.count) + "\n"
        output += message
        error(output)
    }
    
    public func error(_ issue: Interpreter.Error, in source: Source) {
        error(issue.description, in:source, at:issue.location)
    }
    
    public func error(_ issue: Parser.Error, in source: Source) {
        error(issue.description, in:source, at:issue.location)
    }
    
    public func error(_ issue: Scanner.Error, in source: Source) {
        error(issue.description, in:source, at:issue.location)
    }
    
    public func exit(with status: Status) -> Never {
        switch status {
        case .success:
            Darwin.exit(EXIT_SUCCESS)
        case .failure:
            Darwin.exit(EXIT_FAILURE)
        }
    }
    
    public func log(_ message: String, terminator: String = "\n") {
        print(message, separator:"", terminator:terminator)
    }
    
    public func log(_ expression: Expression) {
        print(expression.description)
    }
    
    public func log(_ object: Object) {
        print(object.description)
    }
    
    public func log(_ statement: Statement) {
        print(statement.description)
    }
    
    public func prompt(isContinuation: Bool = false) {
        if isContinuation {
            print("...", separator:"", terminator:" ")
        } else {
            print(">>>", separator:"", terminator:" ")
        }
    }

    public func run() -> Never {
        switch mode {
        case .file(let name):
            do {
                let source = Source(try String(contentsOfFile:name, encoding:.utf8), input:"'\(name)'")
                let result = compile(source)
                exit(with:result)
            } catch let issue {
                error("ScriptError: \(issue.localizedDescription)")
                exit(with:.failure)
            }
        case .repl:
            log("-------------------------------------")
            log(" dali REPL v1.0.0 (press ^C to exit) ")
            log("-------------------------------------")
            var buffer = ""
            while true {
                prompt()
                while true {
                    guard let line = readLine(strippingNewline:false) else { break }
                    buffer += line
                    let source = Source(buffer, input:"<stdin>")
                    if source.needsContinuation {
                        prompt(isContinuation:true)
                    } else {
                        let _ = compile(source)
                        buffer.removeAll(keepingCapacity:true)
                        break
                    }
                }
            }
        case .help:
            var output = ""
            output += "Usage:\n"
            output += "    dali \n"
            output += "    dali <script> \n"
            output += "    dali (-h | --help)"
            log(output)
            exit(with:.success)
        }
    }
    
    private let interpreter: Interpreter
    private let iterm: Bool
    private let mode: Mode
}

/// Start the program
let dali = Dali(CommandLine.arguments)
dali.run()


