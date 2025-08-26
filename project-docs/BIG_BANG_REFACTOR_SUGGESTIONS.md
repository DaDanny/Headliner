Here’s a clean markdown version of the recommendations and checklist you can keep in your repo or notes:

# Headliner Refactor Recommendations & Checklist

## ✅ Key Recommendations

### 1. Bridge Layer (Compile Fast)
- Rename `AppStateAdapter` → `LegacyAppStateBridge`
- Mark as deprecated (`@available(*, deprecated, message: "Use AppCoordinator + Services")`)
- Keep **public API minimal**, prohibit new call sites
- Create a tiny `MenuContent` shim so `HeadlinerApp` compiles cleanly

### 2. Keep AppCoordinator Thin
- `AppCoordinator` = **service wiring only**
- Avoid `@Published` properties in coordinator
- Views should **observe services directly**, not the coordinator

### 3. Concurrency & Performance
- Mark UI-facing services `@MainActor`
- Run heavy work off the main thread (camera discovery, overlay rendering, I/O)
- Reuse a single `CIContext`/`MTLDevice`
- Drop frames under load (avoid queuing) to prevent runaway latency

### 4. SwiftUI Update Hygiene
- Use `.equatable()` or `EquatableView` for views
- Break down large views into focused subviews
- Use `@State` for local UI flags, not global objects
- Replace `.onReceive` storms with async sequences where possible

### 5. Dependency Injection
- Keep a `DependencyContainer` with a **composition root**
- Provide `.live` factory and easy hooks for test mocks
- Example:
  ```swift
  enum CompositionRoot {
    static func makeCoordinator() -> AppCoordinator {
      AppCoordinator(container: .live)
    }
  }

6. Telemetry & Debugging
	•	Add logger categories: .camera, .overlay, .extension, .ui
	•	Emit timing metrics (camera start, overlay render time, extension status)
	•	Gate with build flag (HEADLINER_DEBUG_METRICS)
	•	Optional: hidden “Diagnostics” menu to surface metrics

7. Guardrails
	•	SwiftLint rules:
	•	Forbid new import AppState
	•	Max file length ~300 lines
	•	Cyclomatic complexity threshold
	•	Add one trivial unit test per service immediately so CI enforces structure

⸻

📋 Weekend Checklist

Friday Evening
	•	Rename AppStateAdapter → LegacyAppStateBridge
	•	Make AppCoordinator the real coordinator in HeadlinerApp
	•	Add MenuContent shim so the app compiles

Saturday
	•	Define CameraServiceProtocol
	•	Migrate camera logic (selection, discovery, permissions, start/stop)
	•	Delete camera code from AppState (leave TODOs pointing to new service)
	•	Wire MenuRoot to use camera directly
	•	Add render queue + CIContext reuse in overlay code

Sunday
	•	Create ExtensionServiceProtocol and move extension install/status logic
	•	Replace direct extension checks in UI with coordinator.extensionService.status
	•	Add OSLog timing for:
	•	camera start
	•	extension status check
	•	overlay render (if applicable)
	•	Remove MenuBarViewModel references from new code; mark file deprecated

⸻

🌟 Success Criteria
	•	Compile Fast: App builds cleanly without hacks
	•	Camera Service: Camera selection, start/stop works end-to-end
	•	Extension Service: Status visible via coordinator
	•	Overlay Perf: CIContext reuse + render queue implemented
	•	Code Hygiene: No new AppState usages; services < 300 lines

Want me to also draft you a **SwiftLint config snippet** you can drop into your repo so it enforces those guardrails (file length, forbid AppState, etc.)?