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
// Sampler.swift
// 03/10/2017
// Sampler types for sequences of data
// -----------------------------------------------------------------------------

import Foundation

/**
 
 Samplers & Types:
 - boolean
 - number
 - string
 - color
 - point
 - circle
 - ellipse
 - line
 - square
 - rectangle
 - polygon
 - etc.
 
 TODO: 
 - Need to work on the iteration for 2D, 3D, etc. sampler types
 - If the samples are relatively prime then iteration works okay
 - If not, then there needs to be an alternative form of iteration by bumping forward one iterator
 
 <NumberSampler>
   number()
   1.547
   pi, e
 
 <PointSampler>
   point()
   point(1, 1)
   point(number(), 0)
 
 How to avoid infinite sequences?
 - All samplers are explicitly finite
 e.g. number()           : 1 random number
 e.g. number(count:100)  : 100 random numbers
 
 - Regions use an implicit grid with fixed or adaptive resolution
 
 <BooleanSampler> (boolean("true"), boolean("false"), ...)
 boolean()
 true, false

 <CircleSampler>
 circle(center:<PointSampler>, radius:<NumberSampler>)
 _[center]: <PointSampler>
 _[radius]: <NumberSampler>
 
 _[inside]: <RegionSampler>
 _[border]: <RegionSampler>
 _[outside]: <RegionSampler>
 
 <ColorSampler> (grayscale, HSB, etc.)
 color(red:<NumberSampler>, green:<NumberSampler>, blue:<NumberSampler>)
 color(red:<NumberSampler>, green:<NumberSampler>, blue:<NumberSampler>, alpha:<NumberSampler>)
 _[gray]: <NumberSampler>
 _[alpha]: <NumberSampler>
 _[red]: <NumberSampler>
 _[green]: <NumberSampler>
 _[blue]: <NumberSampler>
 _[hue]: <NumberSampler>
 _[saturation]: <NumberSampler>
 _[brightness]: <NumberSampler>
 
 <LineSampler: RegionSampler>
 line(from:<PointSampler>, to:<PointSampler>)
 _[from]: <PointSampler>
 _[to]: <PointSampler>
 
 <PointSampler>
 point(x:<NumberSampler>, y:<NumberSampler>)
 origin, ...
 _[x]: <NumberSampler>
 _[y]: <NumberSampler>

 <NumberSampler> (number("1.545"), number(true), ...)
 number()
 number(from:0.0, to:1.0, by:0.2)
 pi, e
 1.0, -0.7, 157, ...

 <RegionSampler>
 region()
 _[empty]: <BooleanSampler>
 
 <StringSampler>? (string(true), string(1.545), ...)
 string(parameters:?)
 "Hello world", ...

 # Making a donut
 c0: point(x:0, y:0)
 c1: circle(center:c0, radius:1.0)
 c2: circle(center:c0, radius:2.0)
 d: intersection(c1[outside], c2[inside])
 
 # If & is the intersection operator
 # d: c1[outside] & c2[inside]
 
 <RegionSampler>?
 
 union(of:and:): <RegionSampler>
 intersection(of:and:): <RegionSampler>
 difference(of:and:): <RegionSampler>
 
 r1 & r2 : Intersection
 r1 | r2 : Union
 
 -----
 
 draw(<LineSampler>, stroke:, width:)
 draw(<CircleSampler>, stroke:, width:)
 
 draw(x:stroke:)
 draw(x:fill:)
 draw(x:gradient:)
 
 sample(from:numbers, where:@(number) {})
 
 switch(condition:true:false:)
 
 **/

public struct BooleanSampler: IteratorProtocol {

    public init(_ value: Bool) {
        self.sampler = Sampler1D(value)
    }
    
    public init(count: Int, _ values: @escaping () -> Bool) {
        self.sampler = Sampler1D(count:count, values)
    }
    
    fileprivate init(_ sampler: Sampler1D<Bool>) {
        self.sampler = sampler
    }
    
    public mutating func next() -> Bool? {
        return sampler.next()
    }
    
    fileprivate var sampler: Sampler1D<Bool>
}

//public struct ColorSampler: IteratorProtocol {
//
//    public init() {
//        self.init(Sampler())
//    }
//
//    public init(_ red: Double, _ green: Double, _ blue: Double, _ alpha: Double) {
//        self.init(Sampler(Color(red, green, blue, alpha)))
//    }
//
//    public init(_ generator: @escaping () -> Color?) {
//        self.init(Sampler(generator))
//    }
//
//    fileprivate init(_ sampler: Sampler<Color>) {
//        self.sampler = sampler
//    }
//
//    public mutating func next() -> Color? {
//        return sampler.next()
//    }
//
//    private var sampler: Sampler<Color>
//}

public struct NumberSampler: IteratorProtocol {
    
    public init(_ value: Double) {
        self.sampler = Sampler1D(value)
    }
    
    public init(count: Int, _ values: @escaping () -> Double) {
        self.sampler = Sampler1D(count:count, values)
    }
    
    fileprivate init(_ sampler: Sampler1D<Double>) {
        self.sampler = sampler
    }
    
    public mutating func next() -> Double? {
        return sampler.next()
    }
    
    fileprivate var sampler: Sampler1D<Double>
}

public struct PointSampler: IteratorProtocol {
    
    public init(_ x: NumberSampler, _ y: NumberSampler) {
        self.sampler = Sampler2D(x.sampler, y.sampler)
    }
    
    fileprivate init(_ sampler: Sampler2D<Double, Double>) {
        self.sampler = sampler
    }
    
    public mutating func next() -> (x: Double, y: Double)? {
        return sampler.next()
    }
    
    public var x: NumberSampler {
        return NumberSampler(sampler.x)
    }
    
    public var y: NumberSampler {
        return NumberSampler(sampler.y)
    }
    
    fileprivate var sampler: Sampler2D<Double, Double>
}

/// Sampler1D<X>

public struct Sampler1D<X>: IteratorProtocol {
    
    public init(_ value: X) {
        self.index = 0
        self.count = 1
        self.generator = { return value }
    }
    
    public init(count: Int, _ generator: @escaping () -> X) {
        self.index = 0
        self.count = max(count, 0)
        self.generator = generator
    }
    
    public func map<A>(_ operation: @escaping (X) -> A) -> Sampler1D<A> {
        return Sampler1D<A>(count:count) {
            return operation(self.generator())
        }
    }
    
    public mutating func next() -> X? {
        if index < count {
            let value = generator()
            index += 1
            return value
        }
        return nil
    }
    
    fileprivate var index: Int
    fileprivate let count: Int
    fileprivate let generator: () -> X
}

/// Sampler2D<X, Y>

public struct Sampler2D<X, Y>: IteratorProtocol {
    
    public init(_ x: Sampler1D<X>, _ y: Sampler1D<Y>) {
        self.index = 0
        self.count = (x.count, y.count)
        self.generator = (x.generator, y.generator)
    }
    
    //    public func map<V, W>(_ operation: @escaping (T, U) -> (V, W)) -> Sampler2D<V, W> {
    //        return Sampler1D<U>(count:count) {
    //            return operation(self.generator())
    //        }
    //    }
    
    //    public func merge<U, V>(_ other: Sampler<U>, _ operation: @escaping (T, U) -> V) -> Sampler<V> {
    //        return Sampler<V>(dimensions:dimensions + other.dimensions) {
    //            return operation(self.generator(), other.generator())
    //        }
    //    }
    
    //    public func split<U, V>(count: Int, _ operation: @escaping (T) -> (U, V)) -> (Sampler<U>, Sampler<V>) {
    //        let samplerU = Sampler<U>(dimensions:Array(dimensions.prefix(count))) {
    //            return operation(self.generator()).0
    //        }
    //        let samplerV = Sampler<V>(dimensions:Array(dimensions.dropFirst(count))) {
    //            return operation(self.generator()).1
    //        }
    //        return (samplerU, samplerV)
    //    }
    
    public mutating func next() -> (X, Y)? {
        if index < count.x * count.y {
            let value = (generator.x(), generator.y())
            index += 1
            return value
        }
        return nil
    }
    
    public var x: Sampler1D<X> {
        return Sampler1D(count:count.x, generator.x)
    }

    public var y: Sampler1D<Y> {
        return Sampler1D(count:count.y, generator.y)
    }

    fileprivate var index: Int
    fileprivate let count: (x: Int, y: Int)
    fileprivate let generator: (x: () -> X, y: () -> Y)
}

public struct StringSampler: IteratorProtocol {
    
    public init(_ value: String) {
        self.sampler = Sampler1D(value)
    }
    
    public init(count: Int, _ values: @escaping () -> String) {
        self.sampler = Sampler1D(count:count, values)
    }
    
    fileprivate init(_ sampler: Sampler1D<String>) {
        self.sampler = sampler
    }
    
    public mutating func next() -> String? {
        return sampler.next()
    }
    
    fileprivate var sampler: Sampler1D<String>
}
