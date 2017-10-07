//// -----------------------------------------------------------------------------
//// Copyright (c) 2017, Christopher A. Brown (chris-al-brown)
////
//// Permission is hereby granted, free of charge, to any person obtaining a copy
//// of this software and associated documentation files (the "Software"), to deal
//// in the Software without restriction, including without limitation the rights
//// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//// copies of the Software, and to permit persons to whom the Software is
//// furnished to do so, subject to the following conditions:
////
//// The above copyright notice and this permission notice shall be included in
//// all copies or substantial portions of the Software.
////
//// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//// THE SOFTWARE.
////
//// dali
//// Validator.swift
//// 02/23/2017
//// Semantic validation for parsed expressions
//// -----------------------------------------------------------------------------
//
//import Foundation
//
///// TODO
///// - Need semantic analysis to check for ill-formed expressions
///// - Need complexity reduction to simplify expressions
///// - Need variable scope analysis
//
//public enum SemanticAnalyzer: ExpressionVisitor {
//
//    case unaryOperator(UnaryOperatorAnalyzer)
//    case variableScope(VariableScopeAnalyzer)
//
////    public struct ComplexityReducer: ExpressionVisitor {
////
////        public func visit(_ expression: Expression) -> Validator.Result? {
////            switch expression.symbol {
////            case .assign(let identifier, let rhs):
////                return .assign(identifier, visit(rhs))
////            }
////        }
////    }
//
//    public struct UnaryOperatorAnalyzer: ExpressionVisitor {
//
//        public func visit(_ expression: Expression) -> Validator.Result? {
//            switch expression.symbol {
//            case .unary(let op, let rhs):
//                switch (op, rhs.symbol) {
//                case (_, .assign(_, _)):
//                    return .error(Validator.Error.invalidUnaryOperation(expression.location, op, "an assignment"))
//                case (.positive, .boolean(_)):
//                    return .error(Validator.Error.invalidUnaryOperation(expression.location, op, "a boolean"))
//                case (.negative, .boolean(_)):
//                    return .error(Validator.Error.invalidUnaryOperation(expression.location, op, "a boolean"))
//                case (_, .function(_, _)):
//                    return .error(Validator.Error.invalidUnaryOperation(expression.location, op, "a function definition"))
//                case (_, .list(_)):
//                    return .error(Validator.Error.invalidUnaryOperation(expression.location, op, "a list"))
//                case (_, .map(_)):
//                    return .error(Validator.Error.invalidUnaryOperation(expression.location, op, "a map"))
//                case (.not, .number(_)):
//                    return .error(Validator.Error.invalidUnaryOperation(expression.location, op, "a number"))
//                case (_, .string(_)):
//                    return .error(Validator.Error.invalidUnaryOperation(expression.location, op, "a string"))
//                default:
//                    return nil
//                }
//            default:
//                return nil
//            }
//        }
//    }
//
//
//    public final class VariableScopeAnalyzer: ExpressionVisitor {
//
//        public typealias Scope = Set<String>
//        public typealias Scopes = [Scope]
//        public typealias Locals = [Expression: Int]
//
//        public init() {
//            self.locals = Locals()
//            self.scopes = Scopes()
//        }
//
//        private func define(_ variable: Token.Identifier, within expression: Expression) -> Validator.Result? {
//            if let scope = scopes.last, scope.contains(variable) {
//                return .error(Validator.Error.duplicateVariableDeclaration(expression.location, variable))
//            }
//            if var scope = scopes.popLast() {
//                scope.insert(variable)
//                scopes.append(scope)
//            }
//            return nil
//        }
//
//        private func lookup(_ variable: Token.Identifier, within expression: Expression) {
//            for (index, scope) in scopes.reversed().enumerated() {
//                if scope.contains(variable) {
//                    locals[expression] = index
//                    return
//                }
//            }
//            /// Global variable
//        }
//
//        public func visit(_ expression: Expression) -> Validator.Result? {
//            switch expression.symbol {
//            case .assign(let variable, let rhs):
//                return define(variable, within:expression) ?? visit(rhs)
//            case .binary(let lhs, _, let rhs):
//                return visit(lhs) ?? visit(rhs)
//            case .boolean(_):
//                return nil
//            case .call(let callee, let args):
//                return visit(callee) ?? args.flatMap { visit($0.1) }.first
//            case .function(let args, let body):
//                scopes.append(Scope())
//                let _args = args.flatMap { define($0, within:expression) }.first
//                let _body = body.flatMap { visit($0) }.first
//                scopes.removeLast()
//                return _args ?? _body
//            case .get(let lhs, let index):
//                return visit(lhs) ?? visit(index)
//            case .keyword(_):
//                return nil
//            case .list(let values):
//                return values.flatMap { visit($0) }.first
//            case .map(let values):
//                return values.flatMap { visit($0.1) }.first
//            case .number(_):
//                return nil
//            case .set(let lhs, let index, let rhs):
//                return visit(lhs) ?? visit(index) ?? visit(rhs)
//            case .string(_):
//                return nil
//            case .unary(_, let rhs):
//                return visit(rhs)
//            case .variable(let variable):
//                lookup(variable, within:expression)
//                return nil
//            }
//        }
//
//        private var locals: Locals
//        private var scopes: Scopes
//    }
//
//    public static var allAnalyzers: [SemanticAnalyzer] {
//        return [
//            .unaryOperator(UnaryOperatorAnalyzer()),
//            .variableScope(VariableScopeAnalyzer())
//        ]
//    }
//
//    public func visit(_ expression: Expression) -> Validator.Result? {
//        switch self {
//        case .unaryOperator(let analyzer):
//            return analyzer.visit(expression)
//        case .variableScope(let analyzer):
//            return analyzer.visit(expression)
//        }
//    }
//}
//
//public final class Validator {
//
//    public enum Error: Swift.Error, CustomStringConvertible {
//        case duplicateVariableDeclaration(Source.Location, String)
//        case invalidUnaryOperation(Source.Location, Expression.UnaryOperator, String)
////        case invalidIndex(Source.Location, String)
////        case invalidValue(Source.Location, String)
//
//        public var description: String {
//            switch self {
//            case .duplicateVariableDeclaration(_, let name):
//                return "ProgramError: Variable '\(name)' is already declared in this scope."
//            case .invalidUnaryOperation(_, let op, let thing):
//                return "ProgramError: The unary operator '\(op.rawValue)' cannot be applied to \(thing)."
////            case .invalidIndex(_, let thing):
////                return "IndexError: Can not use \(thing) as an index."
////            case .invalidValue(_, let thing):
////                return "ValueError: Can not use \(thing) as a value."
//            }
//        }
//
//        public var location: Source.Location {
//            switch self {
//            case .duplicateVariableDeclaration(let location, _):
//                return location
//            case .invalidUnaryOperation(let location, _, _):
//                return location
////            case .invalidIndex(let location, _):
////                return location
////            case .invalidValue(let location, _):
////                return location
//            }
//        }
//    }
//
//    public enum Result {
//        case compilation(Expression)
//        case error(Error)
//    }
//
//    public init(_ expressions: [Expression]) {
//        self.expressions = expressions
//    }
//
//    public func validate() throws -> [Expression] {
//        let analyzers = SemanticAnalyzer.allAnalyzers
//        var output: [Expression] = []
//        output.reserveCapacity(expressions.count)
//        for expression in expressions {
//            var input = expression
//            for analyzer in analyzers {
//                if let result = analyzer.visit(input) {
//                    switch result {
//                    case .compilation(let newInput):
//                        input = newInput
//                    case .error(let error):
//                        throw error
//                    }
//                }
//            }
//            output.append(input)
//        }
//        return output
//    }
//
//    //    private func parseIndex() throws -> Expression {
//    //        let start = current
//    //        let index = try parseExpression()
//    //        switch index.symbol {
//    //        case .assign(_, _):
//    //            throw Error.invalidIndex(location(from:start), "an assignment")
//    //        case .binary(_, _, _):
//    //            return index
//    //        case .boolean(_):
//    //            return index
//    //        case .call(_, _):
//    //            return index
//    //        case .function(_, _):
//    //            throw Error.invalidIndex(location(from:start), "a function definition")
//    //        case .get(_, _):
//    //            return index
//    //        case .keyword(_):
//    //            throw Error.invalidIndex(location(from:start), "a reserved keyword")
//    //        case .list(_):
//    //            throw Error.invalidIndex(location(from:start), "a list")
//    //        case .map(_):
//    //            throw Error.invalidIndex(location(from:start), "a map")
//    //        case .number(_):
//    //            return index
//    //        case .set(_, _, _):
//    //            throw Error.invalidIndex(location(from:start), "a setter")
//    //        case .string(_):
//    //            return index
//    //        case .unary(_, _):
//    //            return index
//    //        case .variable(_):
//    //            return index
//    //        }
//    //    }
//
//    //    private func parseValue() throws -> Expression {
//    //        let start = current
//    //        let value = try parseExpression()
//    //        switch value.symbol {
//    //        case .assign(_, _):
//    //            throw Error.invalidValue(location(from:start), "an assignment")
//    //        case .set(_, _, _):
//    //            throw Error.invalidValue(location(from:start), "a setter")
//    //        default:
//    //            return value
//    //        }
//    //    }
//
//    private let expressions: [Expression]
//}
//
