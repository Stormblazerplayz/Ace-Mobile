import ActivityKit
import Foundation

/// A cooking timer shown as a Live Activity (Lock Screen, and the Dynamic Island on iPhone).
struct KitchenTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// When the timer rings.
        var end: Date
        var done: Bool
    }

    /// "Cookies baking"
    var label: String
    /// How long the timer was set for, in seconds.
    var total: Int
}
