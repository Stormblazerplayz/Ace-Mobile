"""Builds data/coding/gen_swift_api.txt: short explanations of Swift standard library members,
SwiftUI views and modifiers, and common Apple frameworks, written by hand from Apple's
documentation and turned into several kid-style wordings each. No network needed."""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
KNOW = os.path.dirname(HERE)
sys.path.insert(0, KNOW)
sys.path.insert(0, HERE)
from check_data import keyset, norm  # noqa: E402
from coding_common import existing  # noqa: E402

OUT = os.path.join(KNOW, "data", "coding", "gen_swift_api.txt")

# type -> {member: explanation}
MEMBERS = {
    "array": {
        "append": "`array.append(x)` adds x to the end of a `var` array. Use `append(contentsOf:)` to add a whole other array.",
        "insert": "`array.insert(x, at: 0)` puts x at that index and shifts the rest along.",
        "remove(at:)": "`array.remove(at: i)` removes and returns the element at index i. It crashes if i is out of range.",
        "removeLast": "`array.removeLast()` removes and returns the last element; it crashes on an empty array. `popLast()` returns nil instead.",
        "removeAll": "`array.removeAll()` empties the array. `removeAll(where:)` removes only items matching a condition, like `removeAll { $0 < 0 }`.",
        "count": "`array.count` is the number of elements.",
        "isEmpty": "`array.isEmpty` is true when the array has no elements. It is clearer than checking `count == 0`.",
        "first": "`array.first` is the first element as an optional, nil if the array is empty. `array.last` is the last.",
        "contains": "`array.contains(x)` returns true if x is in the array. `contains(where:)` checks with a condition.",
        "firstIndex(of:)": "`array.firstIndex(of: x)` returns the index of the first x as an optional, or nil if it is not there.",
        "sorted": "`array.sorted()` returns a new sorted array; `sort()` sorts a var array in place. Use `sorted(by: >)` for biggest first.",
        "reversed": "`array.reversed()` gives the elements in reverse order. Wrap it in `Array(...)` if you need a real array.",
        "map": "`array.map { $0 * 2 }` returns a new array made by changing every element with the closure.",
        "filter": "`array.filter { $0 > 10 }` returns a new array with only the elements for which the closure returns true.",
        "reduce": "`array.reduce(0, +)` combines all elements into one value, here their sum. The first argument is the starting value.",
        "compactMap": "`array.compactMap { Int($0) }` transforms each element and drops any nil results, handy for converting strings to numbers.",
        "flatMap": "`array.flatMap { $0 }` turns an array of arrays into one flat array.",
        "forEach": "`array.forEach { print($0) }` runs the closure for each element. A plain for-in loop does the same and can use break.",
        "enumerated": "`for (index, item) in array.enumerated()` gives each element with its position, starting at 0.",
        "shuffled": "`array.shuffled()` returns the elements in a random order; `shuffle()` shuffles a var array in place.",
        "randomElement": "`array.randomElement()` returns a random element as an optional, nil if the array is empty.",
        "min": "`array.min()` and `array.max()` return the smallest and largest elements as optionals.",
        "joined": "`[\"a\", \"b\"].joined(separator: \", \")` joins an array of strings into one string.",
        "indices": "`array.indices` is the range of valid indexes, so `for i in array.indices` loops safely.",
        "swapAt": "`array.swapAt(i, j)` swaps the elements at two indexes.",
        "prefix": "`array.prefix(3)` gives the first 3 elements, and `suffix(3)` the last 3, without crashing if there are fewer.",
        "allSatisfy": "`array.allSatisfy { $0 > 0 }` returns true if every element passes the test.",
        "zip": "`zip(names, scores)` pairs up two sequences element by element, so you can loop `for (name, score) in zip(names, scores)`.",
    },
    "string": {
        "count": "`text.count` is the number of characters, counting each emoji or accented letter as one.",
        "isEmpty": "`text.isEmpty` is true for an empty string \"\".",
        "uppercased": "`text.uppercased()` returns a copy in capitals, and `lowercased()` in small letters.",
        "hasPrefix": "`text.hasPrefix(\"Mr\")` returns true if the string starts with that text, and `hasSuffix` checks the end.",
        "contains": "`text.contains(\"cat\")` returns true if the text appears in the string.",
        "split": "`text.split(separator: \" \")` cuts a string into an array of pieces. The pieces are Substrings; wrap them in `String(...)` if needed.",
        "replacingOccurrences": "`text.replacingOccurrences(of: \"a\", with: \"b\")` returns a copy with every match replaced. It comes from Foundation, so `import Foundation`.",
        "trimmingCharacters": "`text.trimmingCharacters(in: .whitespacesAndNewlines)` removes spaces and newlines from both ends (Foundation).",
        "components": "`text.components(separatedBy: \",\")` splits a string into an array of Strings (Foundation).",
        "reversed": "`String(text.reversed())` makes a reversed copy of a string.",
        "append": "`text.append(\"!\")` adds to the end of a var string, the same as `text += \"!\"`.",
        "first": "`text.first` is the first Character as an optional. Swift strings cannot be indexed with plain numbers like `text[0]`.",
        "index": "To get the 3rd character use `text[text.index(text.startIndex, offsetBy: 2)]`. Swift uses String.Index because characters can be different sizes.",
        "string interpolation": "Put values into text with backslash and parentheses: `\"Score: \\(score)\"`.",
        "multiline string": "Three double quotes start and end a multi-line string literal, keeping the line breaks inside.",
        "character": "A `Character` is one visible character, like \"a\" or an emoji. Looping `for ch in text` gives Characters.",
        "Int(string)": "`Int(\"42\")` converts text to an Int and returns an optional, nil if the text is not a whole number.",
    },
    "dictionary": {
        "subscript": "`dict[\"key\"]` returns an optional value, nil if the key is missing. `dict[\"key\"] = value` adds or changes, and `= nil` removes it.",
        "default value": "`dict[\"key\", default: 0]` returns 0 when the key is missing, so `counts[word, default: 0] += 1` counts things neatly.",
        "keys": "`dict.keys` and `dict.values` give the keys and values. Dictionaries have no fixed order, so sort them if order matters.",
        "removeValue": "`dict.removeValue(forKey: \"key\")` removes the entry and returns the old value as an optional.",
        "updateValue": "`dict.updateValue(v, forKey: k)` sets a value and returns the old one, or nil if the key was new.",
        "for loop": "`for (key, value) in dict` loops over every entry, in no particular order.",
        "mapValues": "`dict.mapValues { $0 * 2 }` makes a new dictionary with the same keys and changed values.",
        "count": "`dict.count` is how many key-value pairs it has, and `isEmpty` tells if there are none.",
    },
    "set": {
        "insert": "`set.insert(x)` adds x if it is not already there, and returns whether it was inserted.",
        "contains": "`set.contains(x)` checks if x is in the set, very quickly.",
        "union": "`a.union(b)` returns everything in either set, `a.intersection(b)` what is in both, and `a.subtracting(b)` what is only in a.",
        "remove": "`set.remove(x)` removes x and returns it as an optional.",
    },
    "optional": {
        "if let": "`if let name = optionalName { }` runs the block only when there is a value, with name unwrapped inside. Swift 5.7 allows the short `if let name { }`.",
        "guard let": "`guard let user = user else { return }` exits early when the value is nil, and keeps it unwrapped for the rest of the function.",
        "nil coalescing": "`name ?? \"Guest\"` uses the optional's value, or \"Guest\" if it is nil.",
        "optional chaining": "`user?.profile?.name` reads through optionals, giving nil if any step is nil instead of crashing.",
        "force unwrap": "`value!` force unwraps an optional and crashes if it is nil. Avoid it unless you are sure a value exists.",
        "implicitly unwrapped optional": "A type like `String!` is an implicitly unwrapped optional: it can be nil but unwraps itself when used, crashing if nil. Use it rarely.",
    },
}

GLOBALS = {
    "print": "`print(\"Hi\", score)` writes values to the console, separated by spaces. In Xcode it shows in the debug area.",
    "min": "`min(a, b)` returns the smaller value and `max(a, b)` the larger. They take more than two arguments too.",
    "abs": "`abs(-5)` returns 5, the absolute value.",
    "stride": "`stride(from: 0, to: 10, by: 2)` counts 0, 2, 4, 6, 8. Use `through:` instead of `to:` to include the end.",
    "random": "`Int.random(in: 1...6)` gives a random whole number from 1 to 6. `Double.random(in: 0..<1)` and `Bool.random()` work too.",
    "round": "`x.rounded()` rounds a Double to the nearest whole number; `.rounded(.down)` and `.rounded(.up)` force a direction.",
    "squareRoot": "`x.squareRoot()` returns the square root of a Double. `sqrt(x)` works too after `import Foundation`.",
    "pow": "`pow(2.0, 3.0)` returns 8.0. It needs `import Foundation`.",
    "isMultiple": "`n.isMultiple(of: 2)` returns true for even numbers. It is clearer than `n % 2 == 0`.",
    "range": "`1...5` is a closed range including 5, and `1..<5` is a half-open range that stops before 5.",
    "type(of:)": "`type(of: x)` tells you the type of a value at run time, like `Int` or `String`.",
    "assert": "`assert(score >= 0, \"negative score\")` stops a debug build if the condition is false. `precondition` also checks in release builds.",
    "fatalError": "`fatalError(\"message\")` stops the app on purpose with a message, for situations that should never happen.",
    "defer": "`defer { }` runs its block when the surrounding scope ends, however it exits, which is handy for cleanup.",
    "typealias": "`typealias Score = Int` gives an existing type another name to make code clearer.",
    "tuple": "A tuple groups values: `let point = (x: 3, y: 4)` then `point.x`. Functions can return tuples to give back several values.",
    "inout": "An `inout` parameter lets a function change the caller's variable; call it with `&`, like `double(&score)`.",
    "variadic": "A variadic parameter like `func sum(_ numbers: Int...)` accepts any number of values as an array.",
    "argument label": "Swift parameters can have an outside label and an inside name, like `func move(to point: CGPoint)`. Use `_` to skip the label.",
}

SWIFTUI_VIEWS = {
    "Text": "`Text(\"Hello\")` shows read-only text. Style it with modifiers like `.font(.title)` and `.foregroundStyle(.blue)`.",
    "Image": "`Image(\"name\")` shows a picture from your asset catalog, and `Image(systemName: \"star.fill\")` shows an SF Symbol. Add `.resizable()` to scale it.",
    "Button": "`Button(\"Tap me\") { score += 1 }` runs the closure when tapped. Use the label form to put any view inside.",
    "VStack": "`VStack { }` stacks views top to bottom. Give it `spacing:` and `alignment:` to control the layout.",
    "HStack": "`HStack { }` places views side by side, left to right.",
    "ZStack": "`ZStack { }` layers views on top of each other, later ones in front, like a background behind text.",
    "Spacer": "`Spacer()` is flexible empty space that pushes other views apart inside a stack.",
    "List": "`List(items) { item in Text(item.name) }` shows a scrolling list of rows. The items should be Identifiable.",
    "ForEach": "`ForEach(items) { item in ... }` makes a view for each item inside a stack or list. Items need a stable id.",
    "ScrollView": "`ScrollView { }` lets its content scroll. Use `ScrollView(.horizontal)` for sideways scrolling.",
    "NavigationStack": "`NavigationStack { }` gives a navigation bar and lets `NavigationLink` push new screens. It replaces the older NavigationView.",
    "NavigationLink": "`NavigationLink(\"Settings\") { SettingsView() }` pushes a new screen when tapped, inside a NavigationStack.",
    "TabView": "`TabView { }` shows tabs at the bottom. Give each child `.tabItem { Label(\"Home\", systemImage: \"house\") }`.",
    "TextField": "`TextField(\"Name\", text: $name)` is an editable text box bound to a @State string with a dollar sign.",
    "SecureField": "`SecureField(\"Password\", text: $password)` is a text field that hides what you type.",
    "Toggle": "`Toggle(\"Sound\", isOn: $soundOn)` is an on/off switch bound to a Bool.",
    "Slider": "`Slider(value: $volume, in: 0...1)` lets the user drag to pick a number in a range.",
    "Stepper": "`Stepper(\"Lives: \\(lives)\", value: $lives, in: 1...5)` shows plus and minus buttons to change a number.",
    "Picker": "`Picker(\"Color\", selection: $color) { }` lets the user choose one option. Tag each option with `.tag(value)`.",
    "DatePicker": "`DatePicker(\"Birthday\", selection: $date, displayedComponents: .date)` lets the user pick a date.",
    "ProgressView": "`ProgressView()` shows a spinner, and `ProgressView(value: 0.5)` shows a progress bar half full.",
    "Form": "`Form { }` groups controls in a settings-style layout. Use `Section` inside to split it up.",
    "Section": "`Section(\"Account\") { }` groups rows inside a List or Form with an optional header.",
    "Label": "`Label(\"Favorites\", systemImage: \"heart\")` shows an icon and text together.",
    "Color": "`Color.blue` is a view that fills its space with color. Make custom ones with `Color(red: 1, green: 0.5, blue: 0)`.",
    "Rectangle": "`Rectangle()`, `Circle()`, `Capsule()` and `RoundedRectangle(cornerRadius: 12)` are shapes you can `.fill()` or `.stroke()`.",
    "GeometryReader": "`GeometryReader { geo in }` gives you the size of the space a view has, through `geo.size`. Use it only when you really need sizes.",
    "LazyVGrid": "`LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) { }` lays views out in a grid, creating them only as they appear.",
    "LazyVStack": "`LazyVStack` works like VStack inside a ScrollView but only creates rows as they come on screen, which is better for long lists.",
    "Canvas": "`Canvas { context, size in }` lets you draw shapes and images directly, which is fast for many simple drawings like particles.",
    "TimelineView": "`TimelineView(.animation) { context in }` redraws its content on a schedule, every frame with .animation, handy for clocks and simple games.",
    "Menu": "`Menu(\"Options\") { Button(\"Delete\") { } }` shows a button that opens a pop-up menu of actions.",
    "ShareLink": "`ShareLink(item: url)` shows the system share sheet so users can send a link or text to other apps.",
    "ContentUnavailableView": "`ContentUnavailableView(\"No Results\", systemImage: \"magnifyingglass\")` (iOS 17) shows a friendly empty-state screen.",
}

SWIFTUI_MODS = {
    "padding": "`.padding()` adds space around a view; `.padding(.horizontal, 20)` adds it only on chosen sides.",
    "frame": "`.frame(width: 100, height: 50)` sets a size, and `.frame(maxWidth: .infinity)` makes a view stretch to fill the width.",
    "font": "`.font(.title)` sets text style. Built-in styles include .largeTitle, .title, .headline, .body and .caption, and they scale with the user's text size.",
    "foregroundStyle": "`.foregroundStyle(.red)` sets the color of text and symbols. It replaces the older `.foregroundColor`.",
    "background": "`.background(.yellow)` puts a color or view behind a view. Order matters: add padding first to color the padded area.",
    "cornerRadius": "`.clipShape(.rect(cornerRadius: 12))` rounds corners. The old `.cornerRadius()` modifier is deprecated.",
    "clipShape": "`.clipShape(Circle())` cuts a view to a shape, like making a round profile picture.",
    "shadow": "`.shadow(radius: 5)` adds a soft shadow behind a view.",
    "opacity": "`.opacity(0.5)` makes a view half see-through. 0 is invisible and 1 is solid.",
    "offset": "`.offset(x: 10, y: 0)` moves where a view is drawn without changing the layout around it.",
    "rotationEffect": "`.rotationEffect(.degrees(45))` rotates a view.",
    "scaleEffect": "`.scaleEffect(1.5)` draws a view bigger or smaller without changing its layout size.",
    "onTapGesture": "`.onTapGesture { }` runs code when the view is tapped. Use a Button instead for real buttons, for accessibility.",
    "gesture": "`.gesture(DragGesture().onChanged { value in })` adds a gesture like dragging, using `value.translation` to see how far it moved.",
    "onAppear": "`.onAppear { }` runs when the view appears on screen, and `.onDisappear` when it leaves.",
    "task": "`.task { await load() }` starts async work when the view appears and cancels it automatically when the view goes away.",
    "onChange": "`.onChange(of: score) { oldValue, newValue in }` runs when a value changes (this two-parameter form is iOS 17 and later).",
    "sheet": "`.sheet(isPresented: $showSettings) { SettingsView() }` slides up a new screen when the Bool becomes true.",
    "fullScreenCover": "`.fullScreenCover(isPresented: $show) { }` shows a screen that covers everything, unlike a sheet.",
    "alert": "`.alert(\"Game Over\", isPresented: $showAlert) { Button(\"OK\") { } }` shows a pop-up alert when the Bool is true.",
    "confirmationDialog": "`.confirmationDialog(\"Delete?\", isPresented: $ask) { }` shows a set of choices, like an action sheet.",
    "navigationTitle": "`.navigationTitle(\"Home\")` sets the title at the top, on a view inside a NavigationStack.",
    "toolbar": "`.toolbar { ToolbarItem(placement: .topBarTrailing) { Button(\"Add\") { } } }` puts buttons in the navigation bar.",
    "disabled": "`.disabled(true)` greys out a control so it cannot be used.",
    "animation": "`.animation(.spring, value: isOn)` animates changes to a view whenever that value changes.",
    "transition": "`.transition(.slide)` sets how a view animates in and out when it is added or removed inside withAnimation.",
    "ignoresSafeArea": "`.ignoresSafeArea()` lets a view, like a background color, extend under the notch and home indicator.",
    "listStyle": "`.listStyle(.plain)` changes how a List looks; others include .insetGrouped and .sidebar.",
    "buttonStyle": "`.buttonStyle(.borderedProminent)` gives a Button a filled, colored look. `.bordered` is a lighter version.",
    "tint": "`.tint(.green)` sets the accent color for controls like buttons, toggles and sliders.",
    "aspectRatio": "`.aspectRatio(contentMode: .fit)` scales a resizable image to fit without stretching; `.fill` fills the space and may crop.",
    "overlay": "`.overlay { }` draws another view on top of this one, like a badge on an icon.",
    "multilineTextAlignment": "`.multilineTextAlignment(.center)` centers text that wraps onto several lines.",
    "lineLimit": "`.lineLimit(2)` limits text to 2 lines, adding ... if it is longer.",
    "keyboardType": "`.keyboardType(.numberPad)` shows a number keyboard for a TextField on iPhone and iPad.",
    "onSubmit": "`.onSubmit { }` runs when the user presses return in a TextField.",
    "focused": "`.focused($isFocused)` with a `@FocusState` Bool lets you show or hide the keyboard for a field in code.",
    "searchable": "`.searchable(text: $query)` adds a search bar to a navigation view.",
    "refreshable": "`.refreshable { await reload() }` adds pull-to-refresh to a List or ScrollView.",
    "swipeActions": "`.swipeActions { Button(\"Delete\", role: .destructive) { } }` adds buttons that appear when a list row is swiped.",
    "contextMenu": "`.contextMenu { }` shows a menu when the user long-presses a view.",
    "accessibilityLabel": "`.accessibilityLabel(\"Play button\")` tells VoiceOver what a view is, important for icon-only buttons.",
    "environment": "`.environment(\\.colorScheme, .dark)` sets an environment value for a view and its children; `@Environment` reads one.",
    "preferredColorScheme": "`.preferredColorScheme(.dark)` asks for dark mode for that view's presentation.",
    "id": "`.id(value)` gives a view an identity; changing the value makes SwiftUI treat it as a brand new view, which resets its state.",
}

WRAPPERS = {
    "@State": "`@State private var score = 0` stores a small piece of data owned by a view. When it changes, SwiftUI redraws the view.",
    "@Binding": "`@Binding var isOn: Bool` lets a child view read and change a value owned by its parent, which passes it with `$isOn`.",
    "@Observable": "`@Observable class Game { var score = 0 }` (iOS 17) makes a class whose property changes update any SwiftUI view that reads them. It replaces most ObservableObject use.",
    "@Bindable": "`@Bindable var game: Game` lets you make bindings like `$game.name` to an @Observable object's properties.",
    "@Environment": "`@Environment(\\.dismiss) var dismiss` reads a value from the environment; calling `dismiss()` closes a sheet or pops a screen.",
    "@StateObject": "`@StateObject` creates and owns an ObservableObject in a view (the pre-iOS 17 way). With @Observable you use @State instead.",
    "@ObservedObject": "`@ObservedObject` watches an ObservableObject passed in from outside. It is the older system; new code uses @Observable.",
    "@Published": "`@Published var score = 0` inside an ObservableObject announces changes so views update. New code uses @Observable instead.",
    "@AppStorage": "`@AppStorage(\"highScore\") var highScore = 0` saves a small value in UserDefaults and updates the view when it changes.",
    "@FocusState": "`@FocusState var isFocused: Bool` tracks which text field is focused, so you can move focus or hide the keyboard.",
    "@Query": "`@Query var items: [Item]` (SwiftData) fetches saved models and keeps the view updated as they change.",
    "@MainActor": "`@MainActor` makes code run on the main thread, which is required for updating the UI.",
}

FRAMEWORKS = {
    "UserDefaults": "`UserDefaults.standard.set(10, forKey: \"level\")` saves small settings that survive app restarts; read back with `integer(forKey:)`. It is not for big data or secrets.",
    "SwiftData": "SwiftData (iOS 17) saves your own model objects to the device. Mark a class with `@Model`, add `.modelContainer(for: Item.self)` to the app, and fetch with @Query.",
    "Core Data": "Core Data is Apple's older framework for saving structured data on the device. SwiftData is the newer, simpler Swift-first option built on similar ideas.",
    "URLSession": "`let (data, _) = try await URLSession.shared.data(from: url)` downloads data from the internet using async/await.",
    "Codable": "Making a struct `Codable` lets `JSONDecoder` and `JSONEncoder` turn it to and from JSON automatically when the property names match the keys.",
    "JSONDecoder": "`try JSONDecoder().decode(Player.self, from: data)` turns JSON data into a Codable Player struct, throwing if the shape does not match.",
    "FileManager": "`FileManager.default` works with files and folders, like finding the app's documents folder with `URL.documentsDirectory`.",
    "Timer": "`Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in }` runs code every second. In SwiftUI, `.onReceive(Timer.publish(...).autoconnect())` or TimelineView also work.",
    "DispatchQueue": "`DispatchQueue.main.async { }` runs code on the main thread, and `asyncAfter(deadline: .now() + 2)` runs it after a delay. Swift concurrency with `Task` is the newer way.",
    "Task": "`Task { await doWork() }` starts async work from regular code. `try await Task.sleep(for: .seconds(1))` pauses without blocking.",
    "SpriteKit": "SpriteKit is Apple's 2D game framework with sprites, physics, particles and actions. Show a scene in SwiftUI with `SpriteView(scene:)`.",
    "SceneKit": "SceneKit is Apple's older high-level 3D framework. RealityKit is the newer one, especially for AR and visionOS.",
    "RealityKit": "RealityKit is Apple's modern 3D and AR framework, used for AR apps on iPhone and iPad and for visionOS apps.",
    "ARKit": "ARKit tracks the device's position and the world around it through the camera, so you can place virtual things in the real world.",
    "AVFoundation": "AVFoundation plays and records audio and video. `AVAudioPlayer` is a simple way to play a sound file in a game.",
    "GameKit": "GameKit connects your game to Game Center for leaderboards, achievements and multiplayer.",
    "Charts": "Swift Charts (iOS 16) draws bar, line and other charts in SwiftUI with views like `BarMark` and `LineMark`.",
    "MapKit": "MapKit shows maps. In SwiftUI, `Map()` shows an interactive map, and you can add markers and annotations.",
    "Core Location": "Core Location gets the device's location through `CLLocationManager`, after the user gives permission.",
    "PhotosUI": "`PhotosPicker(selection: $item)` from PhotosUI lets users pick photos without giving your app access to their whole library.",
    "CoreML": "Core ML runs machine learning models on the device, fast and private. Create ML can train simple models without much code.",
    "WidgetKit": "WidgetKit makes home screen and lock screen widgets using SwiftUI views and a timeline of entries.",
    "StoreKit": "StoreKit handles in-app purchases and subscriptions. StoreKit 2 uses async/await, like `try await product.purchase()`.",
    "Haptics": "`UIImpactFeedbackGenerator(style: .medium).impactOccurred()` makes a vibration tap. In SwiftUI, `.sensoryFeedback(.success, trigger: value)` (iOS 17) does it declaratively.",
    "Keychain": "The Keychain securely stores small secrets like passwords and tokens. Never store them in UserDefaults.",
    "UIKit": "UIKit is Apple's older UI framework using view controllers. SwiftUI is newer, but you can mix them with UIViewRepresentable and UIHostingController.",
}

entries, seen, seen_k = [], set(), set()


def add(tag, qs, a):
    assert "=>" not in a and "||" not in a and len(a) <= 600, a
    assert not re.search(r"\b(currently|right now|these days|nowadays|the current|at the moment|today's)\b", a, re.I), a
    keep = []
    for q in qs:
        q = re.sub(r"\s+", " ", q.lower()).strip()
        k = keyset(q)
        if not q or "?" in q or norm(q) in seen or (len(k) >= 2 and k in seen_k) or q in keep:
            continue
        keep.append(q)
    if len(keep) < 2:
        return
    for q in keep:
        seen.add(norm(q))
        if len(keyset(q)) >= 2:
            seen_k.add(keyset(q))
    if a[0] in "`$@\\.":
        a = "In Swift, " + a
    entries.append((tag, keep, a))


def words(name):
    """camelCase to plain words: removeAll -> remove all."""
    n = re.sub(r"\(.*?\)|[@:]", " ", name)
    n = re.sub(r"(?<=[a-z])(?=[A-Z])", " ", n)
    return re.sub(r"\s+", " ", n).strip().lower()


def main():
    w, k = existing(OUT)
    seen.update(w)
    seen_k.update(k)
    for typ, members in MEMBERS.items():
        for m, a in members.items():
            mw = words(m)
            add("coding.swift.stdlib", [f"what does {mw} do on a swift {typ}", f"swift {typ} {mw}",
                                         f"how do i use {mw} with a {typ} in swift", f"{typ} {mw} swift"], a)
    for g, a in GLOBALS.items():
        gw = words(g)
        add("coding.swift.stdlib", [f"what does {gw} do in swift", f"swift {gw}", f"how do i use {gw} in swift",
                                     f"{gw} in swift explained"], a)
    for v, a in SWIFTUI_VIEWS.items():
        vw = words(v)
        add("coding.swiftui.views", [f"what is {v.lower()} in swiftui", f"swiftui {vw}", f"how do i use a {vw} in swiftui",
                                     f"{v.lower()} view swiftui"], a)
    for m, a in SWIFTUI_MODS.items():
        mw = words(m)
        add("coding.swiftui.modifiers", [f"what does {m.lower()} do in swiftui", f"swiftui {mw} modifier",
                                         f"how do i use .{m.lower()} in swiftui", f"{mw} swiftui"], a)
    for wpr, a in WRAPPERS.items():
        ww = words(wpr)
        add("coding.swiftui.state", [f"what is {wpr.lower()} in swiftui", f"swiftui {ww}", f"what does {ww} do in swift",
                                     f"{ww} property wrapper"], a)
    for fw, a in FRAMEWORKS.items():
        fwl = fw.lower()
        add("coding.swift.frameworks", [f"what is {fwl} in swift", f"swift {fwl}", f"how do i use {fwl} in my app",
                                        f"{fwl} ios"], a)
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write("# Generated by gen/coding_swift_api.py from hand-written notes on Swift, SwiftUI and Apple frameworks. "
                 "Do not edit by hand.\n")
        tag = None
        for t, qs, a in entries:
            if t != tag:
                fh.write(f"# tag: {t}\n")
                tag = t
            fh.write(" | ".join(qs) + " => " + a + "\n")
    print(len(entries), "entries ->", OUT)


if __name__ == "__main__":
    main()
