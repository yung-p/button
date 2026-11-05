# Swift Cheat Sheet

Nov 3, 2026 · @Philip

## Running code

Keep projects in `~/Developer` (not iCloud-synced). Three ways to run Swift:

| Where | How | Best for |
| --- | --- | --- |
| Terminal | `swift run` inside the package folder | Quick checks, scripts |
| Xcode | `xed .` to open, then ⌘R | Debugging, apps |
| `#Playground` | Block in any file, results on the right | Trying ideas line by line |

```swift
import Playgrounds

#Playground {
    let x = 2 + 3
    print(x)
}
```

Xcode shortcuts: ⌘R run · ⌘B build · ⌘. stop · ⌘⇧Y console · ⌘⇧O open any file · ⌥-click a symbol for docs · ⌃I re-indent.

New command-line package: `swift package init --type executable`. Entry point: `Sources/<name>/main.swift` (or `Sources/main.swift` in older layouts). Top-level code in `main.swift` runs directly; no `main()` function needed.

## Basics

`let` is a constant, `var` can change. Prefer `let`; the compiler warns when a `var` never changes.

```swift
let language = "Italian"      // constant, type inferred as String
var wordCount = 0              // variable, Int
wordCount += 1

let ratio: Double = 0.75       // explicit type
let isDue: Bool = true

// String interpolation
print("\(language): \(wordCount) words")

// Multi-line string
let note = """
    First line
    Second line
    """

/* Block comment */
```

Core types: `Int`, `Double`, `Bool`, `String`, `Character`. No implicit conversion: write `Double(wordCount)` to mix types. Useful string calls: `.count`, `.lowercased()`, `.hasPrefix("ci")`, `.contains("a")`, `.split(separator: " ")`.

## Collections

Arrays, dictionaries and sets are value types: assigning copies them. Declare with `var` to modify.

```swift
// Array
var words = ["ciao", "grazie"]
words.append("prego")
words[0]                      // "ciao"
words.count                   // 3
words.isEmpty                 // false

// Dictionary (lookup returns an optional)
var translations = ["ciao": "hello", "grazie": "thanks"]
translations["prego"] = "you're welcome"
let t = translations["ciao"]  // String? -> Optional("hello")

// Set (unique values)
var seen: Set<String> = ["ciao"]
seen.insert("ciao")           // no duplicate

// Functional helpers
let lengths = words.map { $0.count }           // [4, 6, 5]
let long = words.filter { $0.count > 4 }       // ["grazie", "prego"]
let total = lengths.reduce(0, +)               // 15
let sorted = words.sorted()                    // alphabetical
let first = words.first(where: { $0.hasPrefix("g") })
```

Iterate a dictionary with `for (word, meaning) in translations { … }`. Order is not guaranteed; sort the keys if order matters.

## Control flow

No parentheses needed around conditions; braces are always required.

```swift
let score = 4

if score >= 4 {
    print("easy")
} else if score >= 2 {
    print("good")
} else {
    print("again")
}

// switch must cover every case; no fallthrough by default
switch score {
case 5:        print("perfect")
case 3...4:    print("good")         // closed range
case ..<3:     print("again")
default:       break
}

// Loops
for word in words { print(word) }
for i in 0..<3 { print(i) }                    // 0, 1, 2
for (i, word) in words.enumerated() { print(i, word) }

var n = 0
while n < 3 { n += 1 }

// guard: exit early when a condition fails
func review(_ word: String) {
    guard !word.isEmpty else { return }
    print("Reviewing \(word)")
}
```

Ranges: `a...b` includes `b`, `a..<b` excludes it. `if` can also be an expression: `let label = if score > 3 { "easy" } else { "hard" }`.

## Optionals

An optional (`String?`) holds a value or `nil`. Swift forces you to unwrap it before use. This is the concept that trips up most newcomers.

```swift
var translation: String? = translations["ciao"]

// 1. if let: use it only when present
if let translation {
    print("Means \(translation)")
}

// 2. guard let: unwrap or leave the function
func show(_ key: String) {
    guard let meaning = translations[key] else {
        print("Unknown word")
        return
    }
    print(meaning)       // non-optional from here on
}

// 3. ?? : fall back to a default
let shown = translation ?? "(no translation)"

// 4. Optional chaining: nil if any step is nil
let upper = translation?.uppercased()   // String?

// 5. Force unwrap: crashes on nil. Avoid outside quick tests.
let sure = translation!
```

Rule of thumb: `if let` / `guard let` for logic, `??` for display defaults, `!` almost never.

## Functions and closures

Arguments are labelled at the call site by default. `_` removes the label; a second name gives an external label.

```swift
func greet(name: String) -> String {
    "Ciao, \(name)!"                 // single expression: implicit return
}
greet(name: "Philip")

func square(_ x: Int) -> Int { x * x }
square(4)                              // no label

func move(from start: Int, to end: Int) { }
move(from: 1, to: 5)                   // external labels read like English

func nextInterval(_ days: Int, factor: Double = 2.5) -> Int {
    Int(Double(days) * factor)         // default parameter value
}

// Return several values with a tuple
func stats() -> (count: Int, due: Int) { (10, 3) }
let s = stats(); print(s.due)

// Closures: inline functions
let double = { (x: Int) -> Int in x * 2 }
let shortest = words.sorted { $0.count < $1.count }   // trailing closure, $0/$1 shorthand
```

Parameters are constants inside the function. Use `inout` and `&value` only when you really need to mutate the caller's variable.

## Structs, classes, enums, protocols

Default to `struct`. Structs are copied on assignment; classes are shared references. SwiftUI views and most models are structs; SwiftData models are classes.

```swift
struct Card {
    let word: String
    var interval = 1                    // default value
    var ease = 2.5

    var isNew: Bool { interval == 1 }   // computed property

    mutating func pass() {              // structs need `mutating` to change self
        interval = Int(Double(interval) * ease)
    }
}
var c = Card(word: "ciao")              // memberwise init for free
c.pass()

class Deck {
    var cards: [Card] = []
    init(cards: [Card]) { self.cards = cards }   // classes need an init
}

enum Rating: Int, CaseIterable {
    case again = 0, good, easy

    var label: String {
        switch self {
        case .again: "Again"
        case .good:  "Good"
        case .easy:  "Easy"
        }
    }
}
let r = Rating.good                     // .good when the type is known

enum LoadState {
    case idle, loading
    case done(String)                   // associated value
}

protocol Transcriber {
    func transcribe(_ url: URL) async throws -> String
}
struct FakeTranscriber: Transcriber {
    func transcribe(_ url: URL) async throws -> String { "ciao" }
}

extension Card: CustomStringConvertible {   // add behaviour to an existing type
    var description: String { "\(word) (\(interval)d)" }
}
```

Protocols are Swift's interfaces. Common built-ins to adopt: `Equatable`, `Hashable`, `Codable` (JSON), `Identifiable` (SwiftUI lists).

## Errors and async/await

Functions that can fail are marked `throws` and called with `try`. Slow work (recording, transcription, network) is `async` and called with `await`. WhisperKit uses both.

```swift
enum CardError: Error {
    case emptyWord
}

func makeCard(_ word: String) throws -> Card {
    guard !word.isEmpty else { throw CardError.emptyWord }
    return Card(word: word)
}

do {
    let card = try makeCard("")
    print(card)
} catch CardError.emptyWord {
    print("Say a word first")
} catch {
    print("Other error: \(error)")
}

let maybe = try? makeCard("ciao")      // Card? — nil on error

// async
func fetchMeaning(_ word: String) async -> String {
    try? await Task.sleep(for: .seconds(1))   // pretend this is slow
    return "hello"
}

// In main.swift you can await at top level:
let meaning = await fetchMeaning("ciao")
print(meaning)

// Run two things in parallel
async let a = fetchMeaning("ciao")
async let b = fetchMeaning("grazie")
let both = await [a, b]
```

In SwiftUI, start async work from a view with `.task { await load() }` or `Task { await load() }` inside a button action. Swift 6 checks data races at compile time; if you hit concurrency errors in UI code, mark the type `@MainActor`.

## Python to Swift

| Python | Swift |
| --- | --- |
| `x = 1` | `let x = 1` / `var x = 1` |
| `None` | `nil` (only in optionals: `Int?`) |
| `f"{name}"` | `"\(name)"` |
| `len(xs)` | `xs.count` |
| `xs.append(4)` | `xs.append(4)` |
| `[x*2 for x in xs]` | `xs.map { $0 * 2 }` |
| `[x for x in xs if x > 2]` | `xs.filter { $0 > 2 }` |
| `for i in range(3)` | `for i in 0..<3` |
| `for i, x in enumerate(xs)` | `for (i, x) in xs.enumerated()` |
| `d.get("k", 0)` | `d["k"] ?? 0` |
| `def f(a, b=2):` | `func f(_ a: Int, b: Int = 2)` |
| `lambda x: x*2` | `{ x in x * 2 }` |
| `@dataclass` | `struct` |
| `try / except` | `do { try … } catch { … }` |
| `async def` / `await` | `func … async` / `await` |
| `pip install` | Add a package in `Package.swift` or Xcode → Add Package Dependencies |

Next steps for talk2learn: add a `Card` struct and a tiny SM-2 function in `main.swift` and test them with `swift run`; then create a SwiftUI app project in Xcode (File → New → Project → App) for the first screen. Apple's free [Develop in Swift tutorials](https://developer.apple.com/tutorials/develop-in-swift) are the best guided path into SwiftUI.
