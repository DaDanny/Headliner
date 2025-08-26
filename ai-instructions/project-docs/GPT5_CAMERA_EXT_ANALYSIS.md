Unified Camera Extension Analysis & Improvement Plan (No XPC)

Executive summary

Your current pains (stuck “Starting Camera…”, Meet/Zoom toggle glitches, random preview/VCam desync) come from two root causes:
	1.	Two capture sessions fight for the same physical camera (main app vs. extension).
	2.	Ambiguous, split-brain state (extension vs. app) without reliable acknowledgment.

Final direction (no XPC):
	•	Extension is the single owner of the physical camera (capture + overlay + virtual camera output).
	•	Main app never opens the physical camera. For preview, it reads from the Headliner virtual camera (self‑preview), so the user always sees exactly what Meet/Zoom sees.
	•	Lazy camera start: no camera initialization on launch; start only when (a) an external app selects the Headliner VCam or (b) the user explicitly presses “Start”.
	•	Clear, minimal comms through App Group UserDefaults + Darwin notifications with acknowledged status (no blind fire-and-forget).
	•	Fix state machine (don’t reset app-controlled state on external stop; robust transitions; health checks).
	•	Remove indirection classes that add complexity but not value.

⸻

Target architecture

Physical Camera
     │
     ▼
CameraExtension (sole owner)
  - CaptureSessionManager (extension-only)
  - Overlay render
  - Virtual Camera frames
     │
     ├──> External apps (Meet/Zoom)
     └──> Main App "Self-Preview" (reads Headliner VCam)

Why this beats a “shared-camera” idea without XPC:
	•	No IPC/video sharing complexity.
	•	Eliminates device contention entirely.
	•	Preview = ground truth.

⸻

Key design decisions
	1.	Single owner of capture: Only the extension touches AVCaptureSession.
	2.	Self‑preview in main app: Open the Headliner virtual camera as the preview source.
	3.	Lazy initialization: Remove camera setup from extension init. Start capture only when needed.
	4.	Auto‑start option: If user enables “Auto-start when selected in apps,” extension starts capture when _streamingCounter goes from 0→1.
	5.	State model with acknowledgments: Status persisted in App Group UserDefaults and mirrored with Darwin notifications.
	6.	Tighten managers: Remove/merge CustomPropertyManager and OutputImageManager; simplify ExtensionService; harden CaptureSessionManager (extension‑only).
	7.	No timers unless streaming: Only run the frame tick when at least one consumer exists; pause when none do.
	8.	Never toggle app-controlled state in response to external app stops.

⸻

State machine (extension)

States

.idle        // no consumers; capture stopped; timer off
.starting    // setting up capture (permissions, device IO, buffers)
.streaming   // capture + frame pipeline running
.stopping    // orderly teardown
.error(code) // recoverable/unrecoverable fault

Transitions (high level)
	•	.idle → .starting when:
	•	_streamingCounter increments 0→1 (external app selected VCam), OR
	•	app explicitly requests Start.
	•	.starting → .streaming when capture & first frame ready.
	•	.streaming → .stopping when:
	•	_streamingCounter decrements to 0 and _isAppControlledStreaming == false, OR
	•	app explicitly requests Stop.
	•	.stopping → .idle after teardown completes.
	•	Any → .error(code) on failure; attempt recovery if safe.

Concurrency guards
	•	All transitions through a single serial queue (or lock + small critical sections).
	•	Never change _isAppControlledStreaming in stopStreaming() triggered by external apps.

⸻

App ⇄ Extension communication (no XPC)
	•	App Group UserDefaults keys (example):
	•	HL.selectedDeviceID: String?
	•	HL.autoStartCamera: Bool (default true)
	•	HL.ext.status: String (enum rawValue: idle|starting|streaming|stopping|error)
	•	HL.ext.errorCode: Int?
	•	HL.ext.lastHeartbeatAt: TimeInterval (health)
	•	Darwin notifications:
	•	From app → extension: .HL.request.start, .HL.request.stop, .HL.request.switchDevice
	•	From extension → app: .HL.status.changed (payload-less; app reads status from defaults)

Ack pattern:
	•	App writes “intent” (e.g., HL.requestedAction=start w/ a nonce if you want), posts Darwin notif, then observes HL.ext.status. App UI updates only after seeing starting/streaming, not after arbitrary delays.

⸻

Main app changes
	1.	Remove physical capture
	•	Delete/retire any CaptureSessionManager usage from the main app.
	•	The main app’s camera list is enumeration only (no capture). It writes HL.selectedDeviceID.
	2.	Self‑preview
	•	Open Headliner VCam via AVCaptureDevice and show as the Live Preview.
	•	Result: Preview always matches Meet/Zoom output.
	3.	Start/Stop buttons
	•	“Start” → write HL.isAppControlledStreaming = true, post .HL.request.start notification.
	•	“Stop”  → write HL.isAppControlledStreaming = false, post .HL.request.stop.
	4.	Status binding
	•	Observe HL.ext.status.
	•	UI states:
	•	idle: “Start Camera” visible
	•	starting: spinner “Starting Camera…”
	•	streaming: preview visible
	•	stopping: spinner “Stopping…”
	•	error: show recovery CTA

⸻

Extension changes
	1.	No capture in init
	•	Remove any setupCaptureSession() from initializer.
	•	Defer until .startStreaming() or app’s Start request arrives.
	2.	Auto‑start
	•	On startStreaming():
	•	_streamingCounter += 1
	•	If HL.autoStartCamera == true and not capturing: set _isAppControlledStreaming = true and start capture.
	•	If HL.autoStartCamera == false and not capturing: show splash until app explicitly starts.
	3.	stopStreaming() fix
	•	Decrement counter. If it reaches 0:
	•	Do not set _isAppControlledStreaming = false.
	•	Stop capture only if _isAppControlledStreaming == false.
	•	Otherwise keep capture alive (user started it via app).
	4.	Device switching
	•	Observe HL.selectedDeviceID.
	•	If streaming: rebuild inputs on the fly (atomic switch with brief pause).
	•	If idle: next start uses the new device.
	5.	Timers & buffer pools
	•	Create timer (or CADisplayLink‑ish source) only in .streaming.
	•	Tear down timers and release pools in .stopping → .idle.
	6.	Status + heartbeat
	•	Every transition writes HL.ext.status.
	•	Update HL.ext.lastHeartbeatAt periodically (e.g., every 1–2s) while streaming.
	•	Post .HL.status.changed Darwin notif on transitions.

⸻

Class cleanup
	•	Remove CustomPropertyManager
Fold “is the VCam available?” checks into ExtensionService or a small utility. No placeholder IDs. If you must detect the virtual device from the app side, query AVCaptureDevice for a device name containing “Headliner” (or your vendor ID).
	•	Remove OutputImageManager
Publish the current preview CGImage/NSImage only if the main app truly needs it for non‑VCam views. Otherwise, the self‑preview replaces this.
	•	ExtensionService
Keep SystemExtension lifecycle/installation logic; simplify status detection by reading HL.ext.status instead of heuristic log scraping or device scans.
	•	CaptureSessionManager (extension‑only)
	•	Fix exact device selection (prefer stable uniqueID over localized names).
	•	Serialize permission prompts & session configuration to avoid races.
	•	Clean teardown; handle reconfiguration (device switch) on the same session queue.
	•	Ensure pixel format matches your renderer; reuse CVPixelBuffer pools.

⸻

Error handling & recovery
	•	Health checks (extension side):
	•	If streaming and no frames rendered for N ms → try lightweight recovery (reconnect output), else escalate to .error.
	•	If permission is revoked mid‑run → transition to .error, notify app.
	•	Backoff & retry:
	•	On device busy errors, retry with incremental backoff while showing .error with user hint (“Your camera is in use by X”).
	•	Structured logging:
	•	Log state transitions: fromState → toState (trigger: <reason>).
	•	Tag frame timing (ms), drops, and memory usage at low frequency.

⸻

Performance notes
	•	No work when idle: frame timer off, overlay renderer idle.
	•	Buffer reuse: CVPixelBuffer pool, CIContext reuse.
	•	Overlay updates: apply atomic config snapshots to the render loop (avoid reading mutable state mid‑frame).
	•	Meet/Zoom toggles: external stop shouldn’t drop app-controlled capture if user enabled auto‑start or manually started it.

⸻

Migration plan (incremental, safe)

Day 1–2
	1.	Remove main‑app capture. Implement self‑preview from Headliner VCam.
	2.	Kill init‑time capture in extension; add lazy start.
	3.	Implement HL.ext.status + Darwin status notifications; wire main app UI to it.
	4.	Fix stopStreaming() so it never flips _isAppControlledStreaming.

Day 3–4
1) Add HL.autoStartCamera (default true).
2) Harden CaptureSessionManager (exact device match, serialized configuration, robust teardown).
3) Remove CustomPropertyManager & OutputImageManager.

Day 5+
8) Health checks, error codes, and recovery flows.
9) Logging & light telemetry.
10) Polishing (device switch during streaming, safer overlay application).

⸻

Test matrix
	•	Launch idle: No camera indicator; status=idle.
	•	External first: Open Meet, select Headliner → auto‑start capture; status goes starting → streaming; preview shows camera+overlay.
	•	Toggle video in Meet: stop→start cycles without losing app-controlled state.
	•	App first: Press Start in app with Meet closed; preview works; opening Meet shows same output immediately.
	•	Device switch while streaming: Switch from built‑in to USB; brief pause, resume cleanly.
	•	Permissions revoked mid‑run: Transition to error, recover after re‑grant.
	•	Multiple consumers: Open Meet and QuickTime → _streamingCounter increments; stop one consumer leaves streaming on until all consumers stopped (or app-controlled off).

⸻

Success metrics
	•	0 premature camera activations on launch.
	•	< 500ms preview/VCam sync drift (should be effectively zero with self‑preview).
	•	100% reliable Meet/Zoom toggle cycles over 50 trials.
	•	No device‑in‑use conflicts when the app UI is streaming and an external app joins/leaves.
	•	Crash‑free capture reconfiguration (device switch) over 100 switches.

⸻

Minimal code sketches (illustrative)

Extension: start/stop (core ideas)

func startStreaming() {
  streamQueue.sync {
    _streamingCounter += 1
    persistStatus(.starting)

    if !isCapturing, shouldAutoStartOrAppControlled() {
      _isAppControlledStreaming = true // if auto-start path
      startCaptureLocked() // sets up session, outputs, timer
    } else if isCapturing {
      // already streaming; ensure frame timer is on
      ensureTimerLocked()
    }

    persistStatus(isCapturing ? .streaming : .starting)
  }
}

func stopStreaming() {
  streamQueue.sync {
    _streamingCounter = max(0, _streamingCounter - 1)

    let noExternalConsumers = (_streamingCounter == 0)
    if noExternalConsumers && !_isAppControlledStreaming {
      persistStatus(.stopping)
      stopCaptureLocked() // tear down timer, session, pools
      persistStatus(.idle)
    } // else keep streaming for app-controlled mode
  }
}

App: start/stop (with ack via status)

func startCameraFromApp() {
  setAppGroupBool("HL.isAppControlledStreaming", true)
  postDarwin(".HL.request.start")
  awaitStatus(.starting, timeout: 2.0) // then await .streaming
}

func stopCameraFromApp() {
  setAppGroupBool("HL.isAppControlledStreaming", false)
  postDarwin(".HL.request.stop")
  awaitStatus(.stopping, timeout: 2.0) // then await .idle
}


⸻

What this unifies from the three reviews
	•	From analysis_2 and analysis_3: the “one input owner” principle and removal of dual capture sessions is the decisive fix.
	•	From analysis_2: don’t reset app state when external apps stop; add auto‑start.
	•	From analysis_3: self‑preview via the virtual camera for perfect parity; acknowledged status instead of blind notifications.
	•	From analysis_1: replace fatalError, reduce polling/timers, and keep logging useful but bounded.

This plan keeps your stack simple (no XPC), resolves contention, clarifies state, and produces a UX that “just works” when users pick Headliner in Meet/Zoom—while your app’s preview always shows the exact same output.