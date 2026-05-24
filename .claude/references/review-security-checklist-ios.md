# iOS Security Checklist — Objective Reviewer Reference

This file is loaded into the context of the objective code reviewer sub-agent. Each rule
is checkable against a git diff or file contents with no project history required.

---

## 1. Keychain vs UserDefaults

**Rule: Sensitive data must go in Keychain, never UserDefaults.**

Sensitive data includes:
- Authentication tokens (OAuth tokens, session tokens, API keys)
- Passwords and PINs
- Biometric enrollment results
- Medication names, dosages, supplement schedules (health-adjacent PII)
- Any value the user would consider private health information

**What to flag:**
- `UserDefaults.standard.set(_, forKey:)` where the key name suggests a token, password,
  medication, supplement name, schedule, or reminder tied to health data → CRITICAL
- `UserDefaults.standard.string(forKey:)` reading back values that appear sensitive → CRITICAL
- Storing sensitive data in a `.plist` file directly → CRITICAL
- Keychain wrapper classes that fall back to UserDefaults on error without logging the failure → HIGH

**What is acceptable:**
- Non-sensitive preferences in UserDefaults (theme, onboarding state, display language)
- Keychain via `SecItemAdd`, `SecItemCopyMatching`, or a well-maintained wrapper (KeychainAccess, etc.)
- `@AppStorage` only for non-sensitive preferences

---

## 2. Network Security — TLS Enforcement

**Rule: All network traffic must use HTTPS. No plain HTTP.**

**What to flag:**
- Any URL literal beginning with `http://` (not `https://`) → CRITICAL
- `NSAllowsArbitraryLoads: true` in `Info.plist` without a documented exception → CRITICAL
- `NSExceptionAllowsInsecureHTTPLoads: true` for a production domain → HIGH
- `URLSession` configuration that disables SSL validation
  (`urlSession(_:didReceive:completionHandler:)` calling `.useCredential` unconditionally) → CRITICAL
- Certificate pinning: if the app handles auth or health data and does NOT implement pinning,
  flag as MEDIUM (recommended, not required for pass)

**What is acceptable:**
- `NSExceptionDomains` entries for localhost or development-only domains with a comment
- Certificate pinning via `TrustKit`, `Alamofire` pinning, or manual `SecTrust` evaluation

---

## 3. Input Validation

**Rule: All user-supplied input must be validated before use.**

**Free-text inputs (supplement names, notes, instructions):**
- Must have a non-empty check and a max-length cap before persistence → HIGH if missing
- Must not be interpolated into system calls, SQL, or log strings without sanitization → CRITICAL

**Numeric inputs (dosage, quantity, frequency):**
- Must be validated as positive, within a reasonable range (e.g., 0–10000 mg) → HIGH if missing
- Parsing must handle locale-specific decimal separators → MEDIUM if missing

**Date/time inputs (reminder times, schedule windows):**
- Must reject dates in the past when future dates are required → MEDIUM if missing
- Must validate against the app's supported date range → MEDIUM if missing

**Swift-specific patterns to look for:**
- `Int(userInput)!` — force-unwrapping a parsed numeric → HIGH (crashes on non-numeric input)
- `DateFormatter` without locale setting → MEDIUM (locale-sensitive parsing)
- Regex validation present → acceptable if pattern is not trivially bypassable

---

## 4. Logging and Analytics — PII / Health Data Exposure

**Rule: No PII or health data in logs, crash reports, or analytics payloads.**

**What to flag:**
- `print(supplement.name)`, `print(medication.dosage)`, or similar health data in print statements → CRITICAL
- `os_log("User took \(supplement.name)")` — interpolating health data into any log level → CRITICAL
- `Analytics.track("supplement_added", properties: ["name": supplement.name])` — health data in analytics → CRITICAL
- Error messages passed to crash reporters (Sentry, Firebase Crashlytics) containing health values → CRITICAL
- `debugPrint` or `dump()` on health model objects → HIGH (outputs all properties)

**What is acceptable:**
- Logging event names without payload: `Analytics.track("supplement_added")` → fine
- Logging anonymized identifiers: `Analytics.track("supplement_added", properties: ["id": supplement.id])` → acceptable
- `os_log` with `.debug` level using static strings only → fine

---

## 5. Biometric Authentication Gates

**Rule: Sensitive operations must be gated behind biometric or passcode auth when appropriate.**

**Operations that require a gate:**
- Viewing full medication/supplement history for another person
- Exporting health data
- Disabling reminders for critical medications
- Changing auth credentials or account settings

**What to flag:**
- A view or action that exposes all health data without any `LAContext.evaluatePolicy` check,
  where the PLAN.md or requirements mention auth gates → HIGH
- `LAContext.evaluatePolicy` called but result not checked before proceeding → CRITICAL
- Biometric auth result stored in UserDefaults as a boolean flag → CRITICAL

**What is acceptable:**
- `LAContext.evaluatePolicy(.deviceOwnerAuthentication, ...)` with proper result handling
- Graceful fallback to passcode when biometrics unavailable

---

## 6. Dependency Hygiene

**Rule: Third-party Swift packages must be pinned to specific versions.**

**What to flag:**
- `Package.swift` or `*.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
  absent when SPM dependencies are declared → HIGH
- Dependencies declared with `.upToNextMajor(from:)` for security-critical packages
  (auth, crypto, networking) → MEDIUM
- Dependencies declared with `.branch("main")` or `.branch("master")` → HIGH
- Known CVE-affected package versions (reviewer must flag if version is clearly outdated
  based on package name + version; e.g., Alamofire < 5.6.4 had a known redirect issue) → HIGH

**What is acceptable:**
- `.exact("2.3.1")` or `.upToNextMinor(from: "2.3.0")` for all packages
- `Package.resolved` committed to version control

---

## 7. OWASP Mobile Top 10 — iOS/Swift Manifestations

### M1: Improper Credential Usage
- API keys hardcoded in source files → CRITICAL
- Credentials in `Info.plist` readable by other apps → CRITICAL
- Tokens logged at any level → CRITICAL

### M2: Inadequate Supply Chain Security
- Unverified SPM dependencies → MEDIUM
- Dependencies fetched from non-canonical URLs → HIGH

### M3: Insecure Authentication / Authorization
- Auth state stored only in memory (lost on app kill, re-authenticated without prompt) → HIGH
- Missing auth checks before accessing protected routes/views → HIGH

### M4: Insufficient Input/Output Validation
- See Section 3 above.

### M5: Insecure Communication
- See Section 2 above.

### M6: Inadequate Privacy Controls
- Health data accessible via iOS share sheet without consent gate → HIGH
- iCloud backup not disabled for sensitive Keychain items (`kSecAttrAccessibleAfterFirstUnlock`
  without `kSecAttrSynchronizable: false`) → MEDIUM

### M7: Insufficient Binary Protections
- Jailbreak detection bypassed or absent for an app handling payment data → MEDIUM
- Bitcode disabled without documented reason → LOW

### M8: Security Misconfiguration
- Debug flags left enabled in release builds (`#if DEBUG` missing around debug code) → MEDIUM
- Test credentials in source tree → CRITICAL

### M9: Insecure Data Storage
- See Sections 1 and 4 above.

### M10: Insufficient Cryptography
- MD5 or SHA-1 used for any security purpose → HIGH
- Encryption key stored adjacent to ciphertext → CRITICAL
- `CommonCrypto` used without IV randomization → CRITICAL
