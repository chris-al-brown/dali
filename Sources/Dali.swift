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
    
    public enum Mode {
        case file(String)
        case repl
        case usage
    }
    
    public enum Status {
        case success
        case failure
    }

    public init(_ args: [String]) {
        self.console = Console()
        switch args.count {
        case 1:
            self.mode = .repl
        case 2:
            switch args[1] {
            case "-h", "--help":
                self.mode = .usage
            default:
                self.mode = .file(args[1])
            }
        default:
            self.mode = .usage
        }
    }
    
    public func compile(_ source: Source) -> Status {
        do {
            let scanner = Scanner(source)
            let parser = Parser(try scanner.scan())
            let interpreter = Interpreter()
            (try parser.parse()).forEach {
                console.log($0)
                if let value = interpreter.interpret($0) {
                    print(value)
                } else {
                    print("nil")
                }
            }
            return .success
        } catch let issue as Scanner.Error {
            console.error(issue, in:source)
        } catch let issue as Parser.Error {
            console.error(issue, in:source)
        } catch {
            fatalError("Unexpected error: \(error)")
        }
        return .failure
    }
    
    public func exit(with status: Status) -> Never {
        switch status {
        case .success:
            Darwin.exit(EXIT_SUCCESS)
        case .failure:
            Darwin.exit(EXIT_FAILURE)
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
                console.error("ScriptError: \(issue.localizedDescription)")
                exit(with:.failure)
            }
        case .repl:
            console.log("-------------------------------------")
            console.log(" dali REPL v0.1.0 (press ^C to exit) ")
            console.log("-------------------------------------")
            var buffer = ""
            while true {
                console.prompt()
                while true {
                    guard let line = readLine(strippingNewline:false) else { break }
                    buffer += line
                    let source = Source(buffer, input:"<stdin>")
                    if source.needsContinuation {
                        console.prompt(isContinuation:true)
                    } else {
                        let _ = compile(source)
                        buffer.removeAll(keepingCapacity:true)
                        break
                    }
                }
            }
        case .usage:
            var output = ""
            output += "Usage:\n"
            output += "    dali \n"
            output += "    dali <script> \n"
            output += "    dali (-h | --help)"
            console.log(output)
            exit(with:.success)
        }
    }
    
    private let console: Console
    private let mode: Mode
}
