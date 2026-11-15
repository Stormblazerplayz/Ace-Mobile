// @title Prime Numbers
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Primes.swift and run in Terminal: swiftc -parse-as-library Primes.swift -o primes && ./primes
// @keywords swift prime numbers, swift is prime, swift sieve, swift prime factors
// @about Checks if numbers are prime, lists primes with a sieve, and breaks numbers into prime factors.

import Foundation

@main
struct PrimesProgram {
    static func isPrime(_ n: Int) -> Bool {
        if n < 2 { return false }
        if n < 4 { return true }
        if n.isMultiple(of: 2) { return false }
        var d = 3
        while d * d <= n {  // only need to check up to the square root
            if n.isMultiple(of: d) { return false }
            d += 2
        }
        return true
    }

    // Sieve of Eratosthenes: cross off multiples of each prime
    static func primes(upTo limit: Int) -> [Int] {
        guard limit >= 2 else { return [] }
        var isPrime = [Bool](repeating: true, count: limit + 1)
        isPrime[0] = false
        isPrime[1] = false
        var n = 2
        while n * n <= limit {
            if isPrime[n] {
                for multiple in stride(from: n * n, through: limit, by: n) {
                    isPrime[multiple] = false
                }
            }
            n += 1
        }
        return isPrime.indices.filter { isPrime[$0] }
    }

    static func primeFactors(of number: Int) -> [Int] {
        var n = number
        var factors: [Int] = []
        var d = 2
        while d * d <= n {
            while n.isMultiple(of: d) {
                factors.append(d)
                n /= d
            }
            d += 1
        }
        if n > 1 { factors.append(n) }
        return factors
    }

    static func main() {
        for n in [1, 2, 17, 21, 97, 7919] {
            print("\(n) is \(isPrime(n) ? "prime" : "not prime")")
        }
        print("Primes up to 100: \(primes(upTo: 100))")
        print("There are \(primes(upTo: 100_000).count) primes below 100,000")
        for n in [360, 1001, 65536] {
            let factors = primeFactors(of: n).map(String.init).joined(separator: " x ")
            print("\(n) = \(factors)")
        }
    }
}
