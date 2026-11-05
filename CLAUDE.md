# talk2learn

A small iOS language learning app in Swift and SwiftUI, built as an Xcode iOS App project.
This is the owner's first app, built as a learning project. The app's idea is shared step by step.

## How to work in this repo

The owner wants to understand everything that is built. Follow these rules:

- **Explain the steps first.** Before writing code, say what will be built and list the steps.
- **One function at a time.** Never write more than a single function (or one small type/change of the same size) per step. Stop after it and wait for the owner before going on.
- **Explain what was written.** After each step, briefly explain what the code does and why.
- **No surprises.** Don't add files, dependencies, or features nobody asked for. Mention them as suggestions instead.
- **Don't guess the app idea.** Wait for the owner to describe what to build.

## Structure

- Keep front end and back end separate. The owner focuses on the back end.
  - `UI/`: SwiftUI views. No real logic; they only call into the back end.
  - `Core/`: plain Swift logic (no SwiftUI), e.g. voice recording.
- The app runs on the iPhone simulator (iPhone 17) from Xcode.

## Reference

- `SWIFT_CHEATSHEET.md` has Swift basics.
