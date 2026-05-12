# Phase 1: Project Foundation - Research

**Researched:** 2026-05-07
**Domain:** iOS / SwiftUI / Core Data / Xcode project setup
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Minimum deployment target is **iOS 17**
- **D-02:** Create the Xcode project **manually via Xcode GUI** — do NOT use XcodeGen or any project generation tooling
- **D-03:** Use **@Observable macro + .environment()** for all state management. Do NOT use ObservableObject or @Published. This convention applies to all 9 remaining phases.
- **D-04:** Solid color placeholder icon — single flat color fill, no artwork, no text. Replace in Phase 9.
- **D-05:** During Phase 1, all three tabs (Stack / Today / Schedule) are always visible and navigable — no onboarding gate in this phase.
- **Core Data stack:** PersistenceController singleton (standard Xcode template pattern), shared via `.environment(\.managedObjectContext)` — not revisited

### Claude's Discretion

- Launch screen: simple colored background matching placeholder icon
- Tab bar icons: SF Symbols (e.g. pill, calendar, clock.fill)
- Swift file/folder structure within the Xcode project

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within Phase 1 scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REQ-06 | Xcode project named StackWise with bundle ID `com.stackwise.app` builds and runs on simulator | Xcode GUI project creation flow; bundle ID field in project settings |
| REQ-07 | Core Data schema includes UserProfile, StackItem, ScheduledDose, DailyCheckOff, and FeedbackItem entities with all attributes per SPEC.md data model | Full Core Data entity attribute tables from SPEC.md; Transformable setup for [String] arrays; codegen option selection |
| REQ-08 | Three-tab navigation (Stack / Today / Schedule) renders and tab switching works without crashes | TabView + NavigationStack pattern; @Observable AppState; SF Symbols for tab icons |
</phase_requirements>

---

## Summary

Phase 1 establishes the Xcode project skeleton that all subsequent phases build on. Three distinct technical concerns need correct setup from day one: the Xcode project itself (name, bundle ID, deployment target), the Core Data schema (5 entities, exact attribute types including Transformable arrays, correct codegen option), and the SwiftUI navigation shell (@Observable state, TabView with NavigationStack in each tab).

The single highest-risk item is Core Data's Transformable attributes. UserProfile has two `[String]` array fields (`allergies` and `conditions`) that require a specific transformer name in the `.xcdatamodeld` to avoid a persistent console warning and potential crash on iOS 12+ devices. Since iOS 17 is the floor this warning appears as a runtime error, not a build error — easy to miss if not explicitly set up. The second highest-risk area is mixing `@Observable` and `ObservableObject` patterns: they are incompatible, use different property wrappers (`@State` vs `@StateObject`, `.environment()` vs `.environmentObject()`), and crashes occur silently at runtime if mixed.

All three requirements (REQ-06, REQ-07, REQ-08) are well-understood iOS patterns with no exotic dependencies. This phase involves no external services and no networking. The planner should order tasks as: (1) Xcode project + settings, (2) Core Data schema, (3) PersistenceController singleton, (4) TabView navigation shell, (5) icon + launch screen.

**Primary recommendation:** Use `Manual/None` codegen for Core Data entities (version-control friendly, full visibility), generate files once via `Editor > Create NSManagedObject Subclass`, then add a custom convenience initializer to each entity class. Use `Category/Extension` only if the team prefers auto-sync — but Manual/None is the defensible choice for a version-controlled solo project.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| App icon + launch screen | iOS Asset Catalog / Info.plist | — | Static resources, no code logic |
| Core Data stack (PersistenceController) | App-level singleton | — | Shared container, lives in App struct or dedicated file |
| Core Data schema (5 entities) | Core Data model file (.xcdatamodeld) | NSManagedObject subclass files | Schema is the source of truth; subclasses are generated from it |
| Navigation shell (TabView + NavigationStack) | SwiftUI view layer | — | Pure view composition, no business logic |
| @Observable AppState | App-level state | SwiftUI environment | Injected at App root, accessed by views via @Environment |
| Tab content placeholder views | SwiftUI view layer | — | Empty scaffolding; filled by Phases 2–4 |

---

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Swift | 5.9+ (Xcode 15) | Language | Only supported language for iOS 17 targets |
| SwiftUI | iOS 17 SDK | UI framework | D-03 locks @Observable which requires SwiftUI on iOS 17 |
| Core Data | iOS 17 SDK | User data persistence | SPEC.md §Data & Architecture explicitly locks Core Data (SwiftData excluded) |
| SF Symbols | 5.0 (iOS 17) | Tab bar and UI icons | Apple's standard icon system; no external dependency |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| NSPersistentContainer | iOS 10+ | Core Data stack | The modern Core Data stack — always use over legacy NSPersistentStoreCoordinator setup |
| NSSecureUnarchiveFromDataTransformer | iOS 12+ | Transformable [String] arrays | Required for allergies and conditions attributes on UserProfile |
| Observation framework | iOS 17 | Powers @Observable macro | Automatically included; no import needed beyond `import SwiftUI` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual/None codegen | Class Definition codegen | Class Definition is simpler but hides generated files in Derived Data — changes are not version-controlled and the "undeclared type" Xcode error bites periodically |
| UILaunchScreen (Info.plist) | LaunchScreen.storyboard | Storyboard gives more control but requires an Interface Builder file in a SwiftUI project; Info.plist approach is leaner and sufficient for a solid-color background |
| NavigationStack (iOS 16+) | NavigationView | NavigationView is deprecated since iOS 16; NavigationStack is the correct modern API |

**Installation:** No packages to install. Everything in this phase is part of the Apple SDK.

---

## Architecture Patterns

### System Architecture Diagram

```
App Entry (StackWiseApp.swift)
         |
         | creates PersistenceController.shared
         | creates AppState() [@Observable]
         |
         v
    WindowGroup
         |
         |-- .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
         |-- .environment(appState)
         |
         v
    ContentView (TabView)
    /         |          \
Stack Tab   Today Tab   Schedule Tab
(NavigationStack)  (NavigationStack)  (NavigationStack)
    |
    |-- StackListView (root)
    |       |
    |       |--> AnalysisView (pushed via NavigationLink)
```

Data flows down through the environment. Views read `@Environment(\.managedObjectContext)` for Core Data operations. Views read `@Environment(AppState.self)` for app-level state (e.g., selected tab, navigation paths).

### Recommended Project Structure

```
StackWise/
├── StackWiseApp.swift          # @main, WindowGroup, environment injection
├── ContentView.swift           # TabView with three tabs
├── Persistence.swift           # PersistenceController singleton
├── StackWise.xcdatamodeld/     # Core Data schema (5 entities)
├── Models/
│   ├── AppState.swift          # @Observable global app state
│   ├── UserProfile+CoreData.swift      # NSManagedObject subclass
│   ├── StackItem+CoreData.swift
│   ├── ScheduledDose+CoreData.swift
│   ├── DailyCheckOff+CoreData.swift
│   └── FeedbackItem+CoreData.swift
├── Features/
│   ├── Stack/
│   │   ├── StackListView.swift         # Placeholder
│   │   └── AnalysisView.swift          # Placeholder
│   ├── Today/
│   │   └── TodayView.swift             # Placeholder
│   └── Schedule/
│       └── ScheduleView.swift          # Placeholder
└── Assets.xcassets/
    ├── AppIcon.appiconset/
    └── LaunchBackground.colorset/
```

**Note:** Xcode uses "Groups with Folders" by default in Xcode 15 for new projects — the folder structure above IS the filesystem structure, not just logical groups. [VERIFIED: WebSearch results on Xcode folder structure]

### Pattern 1: PersistenceController Singleton (Xcode Template Standard)

**What:** A struct with a static `shared` instance wrapping `NSPersistentContainer`. Also provides a `preview` instance for SwiftUI Previews with in-memory store.

**When to use:** Always — this is the standard Xcode template pattern for SwiftUI + Core Data.

```swift
// Source: Standard Xcode template, verified against Hacking with Swift
// https://www.hackingwithswift.com/quick-start/swiftui/how-to-configure-core-data-to-work-with-swiftui

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // Insert sample data here for previews
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "StackWise")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
```

**Injection in StackWiseApp.swift:**
```swift
@main
struct StackWiseApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
```

**Access in views:**
```swift
@Environment(\.managedObjectContext) private var viewContext
```

### Pattern 2: @Observable AppState with .environment()

**What:** An @Observable class injected at the app root via `.environment()`, accessed in child views via `@Environment(AppState.self)`.

**When to use:** For any app-level state that multiple views need to share. Do NOT use ObservableObject — D-03 locks @Observable for all phases.

```swift
// Source: nilcoalescing.com/blog/ObservableInSwiftUI/ + Apple migration guide
// https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro

@Observable
final class AppState {
    var selectedTab: Int = 0
    // Add phase-specific state as phases are built
}

// In StackWiseApp.swift — @State owns the instance
@main
struct StackWiseApp: App {
    @State private var appState = AppState()
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)                                // @Observable injection
                .environment(\.managedObjectContext,                   // Core Data injection
                    persistenceController.container.viewContext)
        }
    }
}

// In any child view — retrieve by type
struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView(selection: /* binding */) { ... }
    }
}
```

**Critical gotcha — binding to @Observable properties from @Environment:**

You cannot use `$appState.selectedTab` directly on an `@Environment` property. Use `@Bindable`:

```swift
struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState   // Must be inside body, not as property
        TabView(selection: $appState.selectedTab) { ... }
    }
}
```

[CITED: nilcoalescing.com/blog/ObservableInSwiftUI/ — "@Bindable placement gotcha"]

### Pattern 3: TabView with NavigationStack in Each Tab

**What:** `TabView` at the root of `ContentView`, with each tab containing its own `NavigationStack` for independent navigation state.

**When to use:** Standard iOS multi-tab navigation. NavigationStack replaces the deprecated NavigationView (deprecated iOS 16).

```swift
// Source: Apple Developer Documentation + betterprogramming.pub TabView article
// [VERIFIED: multiple WebSearch sources confirm this as the correct iOS 17 pattern]

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            NavigationStack {
                StackListView()
            }
            .tabItem {
                Label("Stack", systemImage: "pills.fill")
            }
            .tag(0)

            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label("Today", systemImage: "calendar")
            }
            .tag(1)

            NavigationStack {
                ScheduleView()
            }
            .tabItem {
                Label("Schedule", systemImage: "clock.fill")
            }
            .tag(2)
        }
    }
}
```

**Stack tab secondary screen (Analysis):** Push from StackListView using NavigationLink inside the NavigationStack:

```swift
struct StackListView: View {
    var body: some View {
        List {
            NavigationLink("View Analysis") {
                AnalysisView()
            }
        }
        .navigationTitle("My Stack")
    }
}
```

### Pattern 4: Core Data Transformable Attribute ([String] array)

**What:** Correct setup for `allergies` and `conditions` attributes on UserProfile entity which are `[String]` arrays stored as Transformable in Core Data.

**When to use:** Any time a Core Data attribute stores a Swift array or custom type.

In the `.xcdatamodeld` entity inspector:
- **Attribute type:** Transformable
- **Custom Class:** `NSArray`  (NOT `[String]` — Core Data uses NSArray internally)
- **Transformer:** `NSSecureUnarchiveFromData`

Then in the NSManagedObject subclass:
```swift
// Source: zditect.com/blog/1701635.html + Apple Developer Forums thread/110168
// [VERIFIED: multiple Apple Developer Forum threads confirm this exact setup]

@NSManaged public var allergies: [String]?   // Keep as Swift [String]? in Swift
@NSManaged public var conditions: [String]?

// Helper computed property to treat as non-optional:
var allergiesList: [String] { allergies ?? [] }
var conditionsList: [String] { conditions ?? [] }
```

**If Transformer field is left blank:** Xcode logs a deprecation warning at runtime: "NSKeyedUnarchiveFromData" is deprecated. On iOS 17 this is a yellow warning — but it signals incorrect setup that will cause issues with future OS versions. Set the transformer name explicitly.

### Anti-Patterns to Avoid

- **Using ObservableObject anywhere:** Incompatible with `@Observable`. If you mix them, SwiftUI's view update tracking breaks silently. D-03 explicitly forbids this.
- **Placing NavigationStack outside TabView:** Creates a single shared navigation stack across all tabs — tab switches navigate the same stack instead of maintaining independent histories.
- **Using NavigationView:** Deprecated since iOS 16, removed in favor of NavigationStack. Using it triggers deprecation warnings and limits available APIs.
- **Leaving Transformer blank on Transformable attributes:** Causes `NSKeyedUnarchiveFromData` deprecation runtime warning. Always set `NSSecureUnarchiveFromData` explicitly.
- **Accessing `viewContext` off the main thread:** `container.viewContext` is a main-thread-only context. Never pass NSManagedObject instances across threads. For background work, use `container.performBackgroundTask { context in }`.
- **Using `@StateObject` with `@Observable` classes:** `@StateObject` is for ObservableObject only. Use `@State` to own an @Observable instance in the root view.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Persistent container setup | Custom NSPersistentStoreCoordinator stack | NSPersistentContainer | NSPersistentContainer handles thread setup, store loading, and merge policies correctly; hand-rolling misses automaticallyMergesChangesFromParent |
| Transformable [String] storage | JSON encoding/custom value transformer | NSSecureUnarchiveFromDataTransformer (built-in) | Already handles NSSecureCoding and sandboxing; custom transformer required only for custom types |
| Tab bar icons | Custom image assets | SF Symbols | SF Symbols 5.0 (iOS 17) has pill, calendar, clock.fill — exactly what this app needs; auto-supports dark mode and dynamic type |
| Preview Core Data context | Separate preview database file | `PersistenceController.preview` in-memory store | In-memory store is disposable, per-preview, never persists — the standard Xcode template provides this |

**Key insight:** Core Data setup complexity is concentrated in the container initialization and Transformable configuration. Both are solved by the standard Xcode template + one known Transformer name — no custom code needed.

---

## Common Pitfalls

### Pitfall 1: Transformable Attribute Transformer Not Set

**What goes wrong:** UserProfile's `allergies` and `conditions` attributes are Transformable with no transformer name specified. App builds and runs. Console shows: `CoreData: warning: NSKeyedUnarchiveFromData is deprecated`. On a future iOS version this becomes a crash.

**Why it happens:** Xcode's default for Transformable is the legacy `NSKeyedUnarchiveFromData` transformer. You must explicitly override it.

**How to avoid:** In the `.xcdatamodeld` entity inspector for the attribute, set **Transformer** to `NSSecureUnarchiveFromData` and **Custom Class** to `NSArray`.

**Warning signs:** Any `NSKeyedUnarchiveFromData` or `NSKeyedUnarchiveFromDataTransformerName` in the console at launch.

### Pitfall 2: @Observable + @State Ownership Confusion

**What goes wrong:** Developer writes `@ObservedObject var appState: AppState` or `@EnvironmentObject var appState: AppState` in a child view — crashes with "no @Observable class of type AppState was found" or "No ObservableObject found of type AppState".

**Why it happens:** `@Observable` uses different property wrappers than `ObservableObject`. The new system uses `@State` (ownership) and `@Environment(Type.self)` (access). The old system used `@StateObject`, `@ObservedObject`, `.environmentObject()`, and `@EnvironmentObject`.

**How to avoid:** Never use ObservableObject vocabulary with @Observable classes. The mapping is:
- Ownership: `@StateObject` → `@State`
- Receive: `@ObservedObject` → plain `let` or `var`
- Environment inject: `.environmentObject()` → `.environment(instance)`
- Environment read: `@EnvironmentObject` → `@Environment(Type.self)`

**Warning signs:** `@Published` anywhere in the codebase. `ObservableObject` protocol conformance. `.environmentObject()` call.

### Pitfall 3: Core Data Optionality vs Swift Optionality

**What goes wrong:** Developer marks attribute as non-optional in Core Data model expecting Swift type to be non-optional. Generated property is `String?`. Force-unwrapping it crashes when a new unsaved object hasn't had its properties set yet.

**Why it happens:** Core Data validates optionality at save time, not at creation time. A newly created NSManagedObject has nil for all properties until explicitly set. Swift's `String?` accurately reflects this — Core Data's "non-optional" only means "must be non-nil when saved."

**How to avoid:** For Manual/None codegen, declare `@NSManaged` properties as optionals (`String?`, `UUID?`) and use computed non-optional accessors (`var labelValue: String { label ?? "" }`). Set all required properties immediately after creating the managed object.

**Warning signs:** Force-unwrapping `@NSManaged` properties. `EXC_BAD_INSTRUCTION` crash immediately after `NSEntityDescription.insertNewObject`.

### Pitfall 4: Manual Codegen Drift

**What goes wrong:** Developer adds a new attribute to the `.xcdatamodeld` but forgets to add the corresponding `@NSManaged` property to the Swift subclass. The app builds successfully (Core Data doesn't check at compile time) but the property is silently inaccessible, or KVC throws at runtime.

**Why it happens:** Manual/None codegen means Xcode no longer auto-syncs the Swift class with the data model.

**How to avoid:** Whenever the data model changes, immediately update the corresponding subclass file. Treat the `.xcdatamodeld` and its companion Swift file as a matched pair that must always be kept in sync. This is especially critical during Phase 1 when the schema is being defined.

**Warning signs:** Runtime `NSUnknownKeyException` when accessing a property. `@NSManaged var` missing for an attribute that exists in the model.

### Pitfall 5: NavigationStack Tab State Reset

**What goes wrong:** User navigates to AnalysisView inside the Stack tab, then switches tabs, then returns to the Stack tab — they are back at StackListView instead of AnalysisView. This is actually correct default SwiftUI behavior but may surprise developers.

**Why it happens:** Without an explicit `NavigationPath` binding, NavigationStack does not persist its stack across tab switches in iOS 16/17.

**How to avoid:** For Phase 1 this is acceptable — the tab content is all placeholder. Phase 2+ should store each tab's `NavigationPath` in AppState if persisted navigation is required. Document the intention in Phase 1 code with a comment: `// TODO Phase 2: persist navigation path in AppState`.

**Warning signs:** If this behavior is undesirable in later phases, the fix is to store `@State var stackPath = NavigationPath()` in AppState and bind it: `NavigationStack(path: $appState.stackPath)`.

### Pitfall 6: Bundle ID Typo (com.stackwise.app)

**What goes wrong:** Bundle ID entered incorrectly during project creation (e.g., `com.StackWise.app` with capital S, or `com.stackwise.App` with capital A). App builds locally but fails push notification provisioning or App Store Connect matching later.

**Why it happens:** Bundle IDs are case-sensitive. The App Store Connect provisioning profile must match exactly.

**How to avoid:** Set to exactly `com.stackwise.app` (all lowercase) in Project > Signing & Capabilities > Bundle Identifier. Verify immediately after creation.

**Warning signs:** Mismatched bundle ID in `Signing & Capabilities` tab vs what was entered during project wizard.

---

## Code Examples

Verified patterns from research:

### @Observable AppState (Phase 1 minimal version)

```swift
// Source: Apple documentation migration guide + sarunw.com/posts/observation-framework-in-ios17/
@Observable
final class AppState {
    var selectedTab: Int = 0
}
```

### Main App Entry Point

```swift
@main
struct StackWiseApp: App {
    @State private var appState = AppState()    // @State owns @Observable — NOT @StateObject
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(\.managedObjectContext,
                    persistenceController.container.viewContext)
        }
    }
}
```

### Core Data Entity: UserProfile NSManagedObject Subclass (Manual/None codegen)

```swift
// Source: SPEC.md §Data Model + tanaschita.com Core Data subclass article
import CoreData

@objc(UserProfile)
public class UserProfile: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var age: Int16
    @NSManaged public var sex: String?
    @NSManaged public var weightKg: Double
    @NSManaged public var allergies: [String]?       // Transformable — NSArray in model
    @NSManaged public var conditions: [String]?      // Transformable — NSArray in model
    @NSManaged public var wakeTime: Date?
    @NSManaged public var sleepTime: Date?
    @NSManaged public var breakfastTime: Date?
    @NSManaged public var lunchTime: Date?
    @NSManaged public var dinnerTime: Date?
    @NSManaged public var onboardingComplete: Bool
    @NSManaged public var trialStartDate: Date?
    @NSManaged public var subscriptionStatus: String?

    // Convenience accessors for non-optional usage
    var allergiesList: [String] { allergies ?? [] }
    var conditionsList: [String] { conditions ?? [] }
    var subscriptionStatusValue: String { subscriptionStatus ?? "unknown" }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfile> {
        return NSFetchRequest<UserProfile>(entityName: "UserProfile")
    }
}
```

### Core Data Entity: StackItem (key attributes)

```swift
// Source: SPEC.md §Data Model
@objc(StackItem)
public class StackItem: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var label: String?
    @NSManaged public var activeIngredient: String?
    @NSManaged public var itemType: String?           // "supplement" or "drug"
    @NSManaged public var isPrescription: Bool
    @NSManaged public var isInDatabase: Bool
    @NSManaged public var dosage: String?
    @NSManaged public var frequency: String?
    @NSManaged public var addedDate: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var sortOrder: Int16
    @NSManaged public var scheduledDoses: NSSet?      // Inverse of ScheduledDose relationship
}
```

### Core Data Entity: ScheduledDose

```swift
// Source: SPEC.md §Data Model
@objc(ScheduledDose)
public class ScheduledDose: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var timeBlock: String?          // "morning", "afternoon", "evening"
    @NSManaged public var suggestedTime: Date?
    @NSManaged public var position: Int16
    @NSManaged public var stackItem: StackItem?       // Many-to-one relationship
}
```

### Core Data Entity: DailyCheckOff

```swift
// Source: SPEC.md §Data Model
@objc(DailyCheckOff)
public class DailyCheckOff: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?                 // Normalized to midnight
    @NSManaged public var timeBlock: String?          // "morning", "afternoon", "evening"
    @NSManaged public var completed: Bool
    @NSManaged public var completedAt: Date?          // Optional
}
```

### Core Data Entity: FeedbackItem

```swift
// Source: SPEC.md §Data Model
@objc(FeedbackItem)
public class FeedbackItem: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?               // "incorrect_interaction", "schedule_issue", "general"
    @NSManaged public var context: String?            // Optional
    @NSManaged public var body: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var submitted: Bool
}
```

### Placeholder Tab Content View

```swift
// Pattern used for all three tab root views in Phase 1
struct StackListView: View {
    var body: some View {
        // TODO Phase 2: implement actual stack list
        Text("Stack")
            .navigationTitle("My Stack")
    }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `@Published` + `ObservableObject` | `@Observable` macro | iOS 17 (WWDC 2023) | Simpler syntax, granular view updates, fewer property wrappers |
| `@StateObject` / `@ObservedObject` | `@State` (owner) / plain `let` (receiver) | iOS 17 | Different ownership semantics — easy to mix up during migration |
| `.environmentObject()` / `@EnvironmentObject` | `.environment(instance)` / `@Environment(Type.self)` | iOS 17 | Type-based lookup replaces key-path lookup; SwiftUI enforces single instance |
| `NavigationView` | `NavigationStack` | iOS 16 (deprecated) | NavigationStack enables programmatic path control; NavigationView is removed from iOS 18+ |
| Multiple AppIcon sizes | Single 1024×1024 PNG (Xcode 14+ Single Size) | Xcode 14 (2022) | Xcode generates all required sizes from one source |
| LaunchScreen.storyboard | `UILaunchScreen` in Info.plist | Xcode 12 (2020) | For simple colored backgrounds, Info.plist is sufficient; storyboard is legacy but still works |

**Deprecated/outdated:**
- `NavigationView`: Deprecated iOS 16, should not be used in new projects.
- `@Published` on @Observable classes: Does nothing. @Observable tracks access automatically; no per-property annotation needed.
- `NSKeyedUnarchiveFromData` transformer: Deprecated. Use `NSSecureUnarchiveFromData` for all Transformable attributes.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Xcode 15 is the developer's installed Xcode version | Standard Stack | If Xcode 14 is installed, Single Size icon feature still works; @Observable macro still works. Low actual risk. |
| A2 | The developer will build and run on an iOS 17 simulator (not a physical device) for Phase 1 | Environment Availability | If physical device is iOS 16 or lower, @Observable macro behavior is undefined. But D-01 locks iOS 17 target, so simulator selection is straightforward. |
| A3 | Category/Extension codegen is an acceptable alternative to Manual/None | Standard Stack | If the developer prefers Class Definition, generated files are in Derived Data and not version-controlled — acceptable for solo project but not recommended. |

---

## Open Questions (RESOLVED)

1. **Xcode version installed**
   - What we know: All research assumes Xcode 15+ (released Sept 2023), which has Single Size icon support and stable @Observable macro.
   - What's unclear: Exact installed Xcode version on the developer's Mac.
   - Recommendation: The planner should include a verification step: check Xcode version via `xcodebuild -version` before starting, flag if < 15.

2. **ScheduledDose → StackItem relationship cascade delete direction**
   - What we know: SPEC.md says "StackItem → ScheduledDose (one-to-many, cascade delete)". This means deleting a StackItem should delete its ScheduledDoses.
   - What's unclear: The inverse relationship rule (ScheduledDose → StackItem) should be set to "Nullify" in Core Data, not "Cascade" — but SPEC.md only describes the StackItem side.
   - Recommendation: In Core Data model editor, set StackItem → scheduledDoses as `Cascade` delete rule; set ScheduledDose → stackItem inverse as `Nullify`. This matches the SPEC.md intent.

3. **AppState responsibilities in Phase 1**
   - What we know: AppState is introduced as the @Observable state object. In Phase 1 it only needs `selectedTab`.
   - What's unclear: Should AppState also hold the NavigationPath for the Stack tab's NavigationStack, or defer that to Phase 2?
   - Recommendation: Phase 1 AppState is minimal (just `selectedTab: Int`). Add NavigationPath when Phase 2 implements the Stack tab navigation. Document with `// TODO Phase 2` comment.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode (macOS) | All iOS development | ASSUMED ✓ | 15+ assumed | — |
| iOS 17 Simulator | REQ-06 build + run | ASSUMED ✓ | Installed with Xcode 15 | Physical device iOS 17+ |
| macOS (developer machine) | Xcode | ASSUMED ✓ | macOS 13 Ventura minimum for Xcode 15 | — |

**Note:** This phase runs entirely on the developer's Mac. No external services, no networking, no APIs. Environment audit is limited to confirming local toolchain.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (built into Xcode, no install required) |
| Config file | StackWiseTests target in the Xcode project |
| Quick run command | `xcodebuild test -scheme StackWise -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:StackWiseTests` |
| Full suite command | Same (Phase 1 test suite is small) |

**Note:** Xcode includes XCTest targets automatically when you check "Include Tests" during project creation. The planner should ensure the "Include Tests" checkbox is selected.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-06 | Project builds with bundle ID `com.stackwise.app` | Build verification | `xcodebuild build -scheme StackWise` | ❌ Wave 0 — build test |
| REQ-07 | Core Data schema has all 5 entities and attributes | Unit — Core Data stack | `xcodebuild test -scheme StackWise -only-testing:StackWiseTests/CoreDataSchemaTests` | ❌ Wave 0 |
| REQ-08 | Three tabs render and switching works | UI test (manual visual verification acceptable for Phase 1) | Run on simulator, switch all three tabs | ❌ Wave 0 — manual |

**REQ-06 verification note:** Bundle ID cannot be verified by a unit test. Verification is manual: open Project > Signing & Capabilities and confirm value is exactly `com.stackwise.app`. The planner should include this as an explicit verification step.

**REQ-07 test approach:** A minimal Core Data unit test can verify the schema is loadable:
```swift
// StackWiseTests/CoreDataSchemaTests.swift
func testCoreDataSchemaLoads() throws {
    let controller = PersistenceController(inMemory: true)
    let context = controller.container.viewContext
    // Insert one record of each entity type to confirm schema is correct
    let profile = UserProfile(context: context)
    profile.id = UUID()
    profile.onboardingComplete = false
    profile.subscriptionStatus = "unknown"
    XCTAssertNoThrow(try context.save())
}
```

### Sampling Rate

- **Per task:** Build succeeds (no compile errors)
- **Per wave:** `xcodebuild build -scheme StackWise` green + manual simulator tab switching
- **Phase gate:** All three tabs visible and switchable, Core Data stack loads without console warnings, bundle ID confirmed

### Wave 0 Gaps

- [ ] `StackWiseTests/CoreDataSchemaTests.swift` — covers REQ-07 (entity insertion + save)
- [ ] Manual verification checklist for REQ-06 (bundle ID) and REQ-08 (tab switching) — documented in plan tasks, not automated

---

## Security Domain

### Applicable ASVS Categories (ASVS Level 1)

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Phase 1 has no auth |
| V3 Session Management | No | No sessions in Phase 1 |
| V4 Access Control | No | Single-user, no roles |
| V5 Input Validation | No | No user input in Phase 1 (placeholder views) |
| V6 Cryptography | No | No secrets stored in Phase 1 |
| V7 Error Handling | Minimal | `fatalError` in PersistenceController is acceptable in Phase 1 (standard template); replace with graceful error before App Store in Phase 9 |
| V9 Communications | No | No networking in Phase 1 |
| V13 API | No | No external APIs |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Core Data persistent store on-device | Information Disclosure | iOS Data Protection API (enabled by default for NSPersistentContainer on modern iOS); no additional Phase 1 action required |
| `fatalError` in production store loading | Denial of Service | Document this as a known Phase 1 shortcut; Phase 9 polish should replace with a user-facing error screen |

**Security summary:** Phase 1 has no meaningful security surface — no user input, no networking, no authentication, no secrets. Standard iOS sandbox protections apply automatically. The one item to track is the `fatalError` in PersistenceController — acceptable for development, must be addressed before App Store submission.

---

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation — `developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro` — @Observable migration patterns
- Apple Developer Documentation — `developer.apple.com/documentation/xcode/configuring-your-app-icon` — App icon asset catalog
- nilcoalescing.com/blog/ObservableInSwiftUI/ — @Observable with environment, @Bindable gotcha
- sarunw.com/posts/observation-framework-in-ios17/ — iOS 17 @Observable patterns and critical gotcha (nil environment values)
- sarunw.com/posts/launch-screen-using-plist/ — UILaunchScreen Info.plist configuration
- useyourloaf.com/blog/core-data-code-generation/ — Definitive codegen option comparison, Manual/None recommendation
- tanaschita.com/20221114-how-to-handle-non-optional-core-data-values-in-swift/ — Core Data optionality vs Swift optionality

### Secondary (MEDIUM confidence)
- hackingwithswift.com — Core Data + SwiftUI PersistenceController pattern (verified against Xcode template output)
- donnywals.com/comparing-observable-to-observableobjects/ — @State vs @StateObject ownership rules for @Observable
- avanderlee.com/xcode/launch-screen/ — Launch screen options comparison
- betterprogramming.pub/swiftui-navigation-stack-and-ideal-tab-view-behaviour — NavigationStack in TabView pattern
- medium.com/yudiz-solutions/nssecureunarchivefromdatatransformer-in-coredata — Transformable + NSSecureUnarchiveFromDataTransformer setup

### Tertiary (LOW confidence / training knowledge)
- General Xcode project creation flow and bundle ID field location — [ASSUMED] based on training knowledge; planner should verify via Xcode GUI during execution

---

## Metadata

**Confidence breakdown:**
- Standard Stack: HIGH — All libraries are Apple SDK; no third-party dependencies
- Architecture: HIGH — Patterns verified against multiple official and community sources
- Core Data schema attributes: HIGH — Copied verbatim from SPEC.md §Data Model
- Transformable setup: HIGH — Verified across multiple Apple Developer Forum threads and Medium article
- @Observable gotchas: HIGH — Verified against Apple migration guide + two independent blog sources
- Launch screen: MEDIUM — Info.plist approach verified; Storyboard alternative is well-known fallback
- Pitfalls: HIGH — Each pitfall verified with a concrete source explaining root cause

**Research date:** 2026-05-07
**Valid until:** 2026-08-07 (stable Apple SDK — 90 days; re-verify if Xcode major version changes)
