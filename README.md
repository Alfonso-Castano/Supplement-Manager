# StackWise

An iOS app for people who already take supplements and medications. It flags interactions between the items in your stack, builds a daily schedule around your wake, sleep, and meal times, and reminds you when it's time to take each group. I built it entirely through agentic development with Claude Code, released it to TestFlight, and used it as the live case study when I trained the team at Silversea Media on Claude Code.

## What it does

- **Interaction analysis.** Every item in your stack is checked against every other item. Supplement–supplement and supplement–medication conflicts are flagged as critical or advisory, good pairings are shown too, and anything not in the database is listed with a caveat instead of being silently skipped.
- **Smart daily schedule.** Morning, afternoon, and evening blocks built from the times you give during onboarding.
- **Reminders.** A local notification for each block ("Time for your morning supplements") that lists what to take, plus a Today tab to check items off. No server.

## How the interaction data was built

The app ships with a SQLite database ([`StackWise/stackwise.sqlite`](StackWise/stackwise.sqlite)) built by a Python pipeline in [`research/`](research/):

1. **Collect** source pages for 20 common medications and 50 supplements.
2. **Extract** interaction records with severity, mechanism, suggested action, timing, citations, and a confidence level.
3. **Validate and compile**, keeping only medium- and high-confidence records.

The result is 63 interactions (9 critical, 54 advisory) across 70 ingredients. The citations come mostly from the NIH Office of Dietary Supplements and Memorial Sloan Kettering's About Herbs, plus PubMed and MedlinePlus. The pipeline has its own pytest suite in [`research/tests/`](research/tests/).

## Run it

Requires a Mac with Xcode and the iOS 17 SDK or later.

1. Open `StackWise.xcodeproj` in Xcode.
2. Pick an iPhone simulator and press Run.
3. Tests: Product > Test (the `StackWiseTests` target).

## Built with

Swift, SwiftUI, Core Data, SQLite, and UserNotifications for the app; Python for the data pipeline; Astro for the landing page in [`landing/`](landing/). Planned and built with Claude Code using the GSD workflow; the planning trail is in [`.planning/`](.planning/).

## Status

Paused. It reached TestFlight but was never released on the App Store. The lesson I kept: research distribution before building.

*StackWise is a personal project, not medical advice. Check with a doctor or pharmacist before changing what you take.*
