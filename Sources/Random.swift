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
// Random.swift
// 02/22/2017
// Random number generator based on xoroshiro128+ (see LICENSE.md for more info)
// -----------------------------------------------------------------------------

import Foundation

public final class DevURandom: CustomStringConvertible {
    
    public init() {
        self.handle = FileHandle(forReadingAtPath:"/dev/urandom").unsafelyUnwrapped
    }
    
    deinit {
        handle.closeFile()
    }
    
    public func randomBytes() -> UInt64 {
        var output: UInt64 = 0
        read(handle.fileDescriptor, &output, MemoryLayout<UInt64>.size)
        return output
    }
    
    public var description: String {
        return "/dev/urandom"
    }

    private let handle: FileHandle
}

public struct Xoroshiro128Plus: CustomStringConvertible {
    
    /// Returns a uniform value in the half-open range [0.0, 1.0)
    public static func bitCast(seed: UInt64) -> Double {
        let kExponentBits = UInt64(0x3FF0000000000000)
        let kMantissaMask = UInt64(0x000FFFFFFFFFFFFF)
        let u = (seed & kMantissaMask) | kExponentBits
        return unsafeBitCast(u, to:Double.self) - 1.0
    }
    
    public init() {
        let entropy = DevURandom()
        var seed: (UInt64, UInt64) = (entropy.randomBytes(), entropy.randomBytes())
        while seed.0 == 0 && seed.1 == 0 {
            seed = (entropy.randomBytes(), entropy.randomBytes())
        }
        self.init(seed.0, seed.1)
    }
    
    public init(_ seed0: UInt64, _ seed1: UInt64) {
        precondition(max(seed0, seed1) > 0, "A 128-bit seed value of 0x0 is strictly not allowed")
        self.seed = (seed0, seed1)
    }
    
    public mutating func randomBool() -> Bool {
        return nextSeed() % 2 == 0
    }
    
    public mutating func randomDouble() -> Double {
        return Xoroshiro128Plus.bitCast(seed:nextSeed())
    }
    
    public mutating func randomInt(lessThan value: Int) -> Int {
        let kLength = UInt64(value)
        let kEngine = UInt64.max
        let kExcess = kEngine % kLength
        let kLimit = kEngine - kExcess
        var vSeed = nextSeed()
        while vSeed > kLimit {
            vSeed = nextSeed()
        }
        return Int(vSeed % kLength)
    }
    
    private mutating func nextSeed() -> UInt64 {
        let s0 = seed.0
        var s1 = seed.1
        s1 ^= s0
        seed.0 = ((s0 << 55) | (s0 >> 9)) ^ s1 ^ (s1 << 14)
        seed.1 = ((s1 << 36) | (s1 >> 28))
        return seed.0 &+ seed.1
    }
    
    public var description: String {
        let seed0 = String(seed.0, radix:16, uppercase:false)
        let seed1 = String(seed.1, radix:16, uppercase:false)
        return "Xoroshiro128Plus(0x\(seed0)|0x\(seed1))"
    }

    public var seed: (UInt64, UInt64)
}
