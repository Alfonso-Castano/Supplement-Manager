# Code Quality Checklist — Objective Reviewer Reference

This file is loaded into the context of the objective code reviewer sub-agent. Each rule
is checkable against a git diff or file contents with no project history required.

---

## 1. Swift-Specific Antipatterns

### Force Unwrap (`!`)
**Severity: HIGH in production paths, LOW in test code**

- `someOptional!` in any file outside `*Tests.swift` or `*Spec.swift` → HIGH
- `as! SomeType` in production code without a guard → HIGH
- `try!` in production code → HIGH
- Exception: `IBOutlet` force unwraps are standard UIKit practice → acceptable
- Exception: `fatalError("unreachable")` with a documented invariant → acceptable

**Pattern to catch:**
```swift
// WRONG — crashes if nil
let value = someOptional!

// RIGHT
guard let value = someOptional else { return }
// or
let value = someOptional ?? defaultValue
```

### Implicitly Unwrapped Optionals (`Type!` in declarations)
**Severity: MEDIUM**

- Property declared as `var name: String!` where it could be `String?` or `String` → MEDIUM
- Exception: `@IBOutlet var label: UILabel!` — UIKit convention → acceptable
- Exception: setUp/tearDown test fixtures → acceptable

### Retain Cycles
**Severity: HIGH**

- Closure that captures `self` without `[weak self]` or `[unowned self]` where `self`
  holds a reference to the closure → HIGH
- Pattern: `DispatchQueue.main.async { self.doSomething() }` inside a class that
  stores a reference to the queue or the closure → HIGH
- Pattern: Timer callbacks without weak capture → HIGH
- `[unowned self]` where `self` could be deallocated before the closure fires → HIGH
  (prefer `[weak self]` in ambiguous lifetime cases)

### Unstructured Concurrency
**Severity: MEDIUM to HIGH**

- `DispatchQueue.main.async` used to update UI from a background thread instead of
  `@MainActor` or `await MainActor.run {}` in Swift 5.5+ code → MEDIUM
- `Task.detached {}` used where a structured `Task {}` would suffice → MEDIUM
- `Task {}` fire-and-forget inside a ViewModel without cancellation tracking → MEDIUM
- Multiple `DispatchQueue` usages mixing `.main` and `.global()` without documented
  thread ownership → MEDIUM

### @MainActor Misuse
**Severity: MEDIUM**

- `@MainActor` annotation on a class that performs network I/O synchronously → MEDIUM
  (blocks the main thread)
- Missing `@MainActor` on a class that drives SwiftUI `@Published` properties where
  `ObservableObject` conformance is present → HIGH (data race risk in Swift 6)
- `nonisolated` on a method that accesses `@MainActor`-isolated state → HIGH

---

## 2. Function Design

### Single Responsibility
**Severity: MEDIUM**

A function violates single responsibility when it:
- Performs network I/O AND parses a response AND updates UI state in the same body → MEDIUM
- Has more than one `// MARK: —` comment worth of logic → MEDIUM
- Has 3+ distinct early-return conditions for unrelated reasons → MEDIUM

### Parameter Count
**Severity: MEDIUM**

- Functions with > 5 parameters where a struct or configuration object would be clearer → MEDIUM
- Initializers with > 6 parameters without a builder pattern → MEDIUM

### Side Effects
**Severity: MEDIUM**

- Functions named as queries (`get`, `fetch`, `compute`) that mutate state as a side effect → MEDIUM
- `@discardableResult` on a function where the return value carries error information → MEDIUM

---

## 3. Error Handling

### Silent Catches
**Severity: HIGH**

- Empty catch block: `catch {}` → HIGH
- `catch { _ = error }` or similar discard patterns → HIGH
- `try?` used where an error should surface to the user or be logged → MEDIUM
  (acceptable for truly optional operations — flag when used on auth or data persistence calls)

### Typed Throws (Swift 6+)
**Severity: LOW**

- Functions that always throw the same concrete error type but declare `throws` instead
  of `throws SomeError` → LOW (style, not a bug)

### Error Propagation
**Severity: MEDIUM**

- Errors swallowed at a Service layer and replaced with `nil` return values → MEDIUM
  (caller cannot distinguish "not found" from "network error")
- User-facing error messages that expose internal error details (`error.localizedDescription`
  passed directly to UI) → MEDIUM

---

## 4. Test Coverage

### ViewModel Tests
**Adequate coverage for a ViewModel requires:**
- At least one test per public `@Published` property that can change
- At least one test per public method that triggers a state change
- At least one test for the error state (if the ViewModel can fail)

**Flag:**
- ViewModel with > 3 `@Published` properties and zero corresponding tests → MEDIUM
- ViewModel with async methods and no async tests (missing `async` keyword in test) → MEDIUM

### Store Tests
**Adequate coverage for a Store/Repository requires:**
- At least one test for a successful read and a successful write
- At least one test for a persistence failure path (corrupt data, missing file)
- Mocked persistence layer (tests must not write to production UserDefaults or Keychain)

**Flag:**
- Store with `save()` and `load()` methods and zero tests → MEDIUM
- Tests that read/write real `UserDefaults.standard` without resetting after test → HIGH
  (test pollution — can cause false positives/negatives in CI)

### Service Tests
**Adequate coverage for a networking Service requires:**
- Mocked `URLSession` or `URLProtocol` — never real network calls in unit tests → HIGH if missing
- At least one test for success response parsing
- At least one test for error response handling (4xx, 5xx, timeout)

---

## 5. Naming — Swift API Design Guidelines

**Severity: LOW for style, MEDIUM for clarity failures at call site**

### Rules to check:
- Method names include all needed words for clarity at call site:
  `insert(at:)` not `insert(_:_:)` → MEDIUM if ambiguous
- Boolean properties/methods should read as assertions:
  `isEnabled`, `hasSupplements`, `canDelete` not `enabled`, `supplements`, `delete` → LOW
- Names at call site should not repeat type information:
  `supplementArray` → `supplements`; `colorValue` → `color` → LOW
- Protocol names should be nouns (`Supplement`), adjectives (`Schedulable`), or end in `-able`/`-ible` → LOW
- Generic type parameters should be `T`, `U`, or a descriptive noun (`Element`, `Key`) not single letters
  like `A`, `B` → LOW

---

## 6. Dead Code Indicators

**Severity: LOW to MEDIUM**

- Unused imports (`import Foundation` when only `import UIKit` is used, etc.) → LOW
- Variables declared but never read (`let _ = someComputation()` is acceptable; `let result = …`
  followed by no use of `result` → LOW)
- Commented-out code blocks (> 3 lines) with no explanatory comment → LOW
- `TODO:` or `FIXME:` comments in production code that reference completed tasks → LOW
- Unreachable `else` branches after exhaustive `switch` on an enum → MEDIUM
- `@available(*, deprecated)` methods that are still called within the same codebase → MEDIUM
- Protocol conformances declared but not actually used anywhere → LOW
