// @title Error Handling
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Errors.swift and run in Terminal: swiftc -parse-as-library Errors.swift -o errors && ./errors
// @keywords swift error handling, swift throws, swift do try catch, swift custom error, swift try optional
// @about Shows how a function can throw an error, and how to catch it with do, try and catch.

import Foundation

enum ShopError: Error {
    case outOfStock(item: String)
    case notEnoughMoney(needed: Int)
}

struct CornerShop {
    var stock = ["apple": 3, "cookie": 0, "juice": 5]
    let prices = ["apple": 2, "cookie": 3, "juice": 4]

    // throws means this function might fail with an error
    mutating func buy(_ item: String, wallet: inout Int) throws -> String {
        guard let count = stock[item], count > 0 else {
            throw ShopError.outOfStock(item: item)
        }
        let price = prices[item] ?? 0
        guard wallet >= price else {
            throw ShopError.notEnoughMoney(needed: price - wallet)
        }
        wallet -= price
        stock[item] = count - 1
        return "You bought a \(item)!"
    }
}

@main
struct ErrorsProgram {
    static func main() {
        var shop = CornerShop()
        var wallet = 7

        for item in ["apple", "cookie", "juice", "juice"] {
            do {
                let message = try shop.buy(item, wallet: &wallet)
                print("\(message) Money left: $\(wallet)")
            } catch ShopError.outOfStock(let name) {
                print("Sorry, no more \(name)s.")
            } catch ShopError.notEnoughMoney(let needed) {
                print("You need $\(needed) more for that.")
            } catch {
                print("Something else went wrong: \(error)")
            }
        }

        // try? turns an error into nil, handy when you don't care why it failed
        let result = try? shop.buy("cookie", wallet: &wallet)
        print("Trying again: \(result ?? "no luck")")
    }
}
