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
            let parser = Parser(try scanner.scan())
            let validator = Validator(try parser.parse())
            let expressions = try validator.validate()
            expressions.forEach { console.log($0) }
            return .success
        } catch let issue as Scanner.Error {
            console.error(issue, in:source)
        } catch let issue as Parser.Error {
            console.error(issue, in:source)
        } catch let issue as Validator.Error {
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
    
    private func random(_ xoroshiro: inout Xoroshiro128Plus, complexity: Int) -> Expression {
        let id = 0
        let location = "".unicodeScalars.startIndex..<"".unicodeScalars.endIndex
        switch complexity {
        case 0:
            switch xoroshiro.randomDouble() {
            case 0.00..<0.20:
                return Expression(id, .boolean(xoroshiro.randomBool()), location)
            case 0.20..<0.40:
                return Expression(id, xoroshiro.randomBool() ? .variable("person") : .variable("circle"), location)
            case 0.40..<0.60:
                return Expression(id, xoroshiro.randomBool() ? .keyword(.pi) : .keyword(.e), location)
            case 0.60..<0.80:
                return Expression(id, .number(xoroshiro.randomDouble()), location)
            default:
                return Expression(id, .string("Hello world"), location)
            }
        case 1:
            let newComplexity = complexity - 1
            switch xoroshiro.randomDouble() {
            case 0.00..<0.33:
                return Expression(id, .function(["x", "y"], [random(&xoroshiro, complexity:newComplexity)]), location)
            case 0.33..<0.66:
                return Expression(id, .list([random(&xoroshiro, complexity:newComplexity)]), location)
            default:
                return Expression(id, .map(["name": random(&xoroshiro, complexity:newComplexity)]), location)
            }
        default:
            let newComplexity = complexity - 1
            switch xoroshiro.randomDouble() {
            case 0.0..<0.2:
                return Expression(id, .assign("age", random(&xoroshiro, complexity:newComplexity)), location)
            case 0.2..<0.4:
                return Expression(id, .unary(.not, random(&xoroshiro, complexity:newComplexity)), location)
            case 0.4..<0.6:
                let index: Expression = random(&xoroshiro, complexity:newComplexity)
                if xoroshiro.randomBool() {
                    return Expression(id, .get(random(&xoroshiro, complexity:newComplexity), index), location)
                } else {
                    return Expression(id, .set(random(&xoroshiro, complexity:newComplexity), index, random(&xoroshiro, complexity:newComplexity)), location)
                }
            case 0.6..<0.8:
                return Expression(id, .binary(random(&xoroshiro, complexity:newComplexity), .add, random(&xoroshiro, complexity:newComplexity)), location)
            default:
                return Expression(id, .call(random(&xoroshiro, complexity:newComplexity), ["x": random(&xoroshiro, complexity:newComplexity), "y": random(&xoroshiro, complexity:newComplexity)]), location)
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
            let expression: Expression = random(&xoroshiro, complexity:3)
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
