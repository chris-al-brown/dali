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
        case test
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
            case "-t", "--test":
                self.mode = .test
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
            let tokens = try scanner.scan()
            do {
                let parser = Parser(tokens)
                let expressions = try parser.parse()
                expressions.forEach { console.log($0) }
                return .success
            } catch let issue as Parser.Error {
                console.error(issue, in:source)
                return .failure
            } catch let other {
                fatalError("Expected a ParserError: \(other)")
            }
        } catch let issue as Scanner.Error {
            console.error(issue, in:source)
            return .failure
        } catch let other {
            fatalError("Expected a ScannerError: \(other)")
        }
    }
    
    public func exit(with status: Status) -> Never {
        switch status {
        case .success:
            Darwin.exit(EXIT_SUCCESS)
        case .failure:
            Darwin.exit(EXIT_FAILURE)
        }
    }
    
    private func random(_ xoroshiro: inout Xoroshiro128Plus, complexity: Int) -> AST.Expression {
        switch complexity {
        case 0:
            return .primary(random(&xoroshiro, complexity:0))
        default:
            let newComplexity = complexity - 1
            switch xoroshiro.randomDouble() {
            case 0.0..<0.2:
                return .assign("age", random(&xoroshiro, complexity:newComplexity))
            case 0.2..<0.4:
                return .unary(.not, random(&xoroshiro, complexity:newComplexity))
            case 0.4..<0.6:
                let index: AST.Index = random(&xoroshiro, complexity:newComplexity)
                if xoroshiro.randomBool() {
                    return .get(random(&xoroshiro, complexity:newComplexity), index)
                } else {
                    return .set(random(&xoroshiro, complexity:newComplexity), index, random(&xoroshiro, complexity:newComplexity))
                }
            case 0.6..<0.8:
                return .binary(random(&xoroshiro, complexity:newComplexity), .add, random(&xoroshiro, complexity:newComplexity))
            default:
                return .call(random(&xoroshiro, complexity:newComplexity), ["x": random(&xoroshiro, complexity:newComplexity), "y": random(&xoroshiro, complexity:newComplexity)])
            }
        }
    }

    private func random(_ xoroshiro: inout Xoroshiro128Plus, complexity: Int) -> AST.Primary {
        switch complexity {
        case 0:
            switch xoroshiro.randomDouble() {
            case 0.00..<0.20:
                return .boolean(xoroshiro.randomBool())
            case 0.20..<0.40:
                return xoroshiro.randomBool() ? .identifier("person") : .identifier("circle")
            case 0.40..<0.60:
                return xoroshiro.randomBool() ? .keyword(.pi) : .keyword(.e)
            case 0.60..<0.80:
                return .number(xoroshiro.randomDouble())
            default:
                return .string("Hello world")
            }
        default:
            let newComplexity = complexity - 1
            switch xoroshiro.randomDouble() {
            case 0.00..<0.33:
                return .function(["x", "y"], [random(&xoroshiro, complexity:newComplexity)])
            case 0.33..<0.66:
                return .list([random(&xoroshiro, complexity:newComplexity)])
            default:
                return .map(["name": random(&xoroshiro, complexity:newComplexity)])
            }
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
        case .test:
            var xoroshiro = Xoroshiro128Plus()
            let formatter = Console.Formatter(useColor:false)
            let expression: AST.Expression = random(&xoroshiro, complexity:2)
            let source = Source(expression.accept(formatter), input:"</dev/urandom>")
            let result = compile(source)
            exit(with:result)
        case .usage:
            var output = ""
            output += "Usage:\n"
            output += "    dali \n"
            output += "    dali <script> \n"
            output += "    dali (-t | --test) \n"
            output += "    dali (-h | --help)"
            console.log(output)
            exit(with:.success)
        }
    }
    
    private let console: Console
    private let mode: Mode
}
