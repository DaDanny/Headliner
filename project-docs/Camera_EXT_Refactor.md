Goal

Make the camera extension codebase easier to read, grep, and debug without changing behavior. We'll refactor the monolithic CameraExtensionProvider.swift (currently ~1400 lines) by splitting CameraExtensionDeviceSource into two concern-focused extensions, while keeping the existing three core classes together.

Current Structure (to be refactored):

CameraExtension/
  CameraExtensionProvider.swift              // 1400+ lines - contains all three classes (TO SPLIT)
  CameraExtensionDiagnostics.swift          // diagnostic system (KEEP UNCHANGED)
  CameraExtensionErrorManager.swift         // error handling (KEEP UNCHANGED)
  CameraExtensionPerformanceManager.swift   // performance monitoring (KEEP UNCHANGED)
  Rendering/
    CameraOverlayRenderer.swift             // overlay rendering (KEEP UNCHANGED)
  main.swift                                 // entry point (KEEP UNCHANGED)
  CameraExtension.entitlements              // system permissions (KEEP UNCHANGED)
  Info.plist                                 // bundle info (KEEP UNCHANGED)

Plan (middle-ground structure)

Target folders & files (6–7 total):

CameraExtension/
  Core/
    CameraExtensionDeviceSource.swift          // root: properties, init, light CMIO conformance
    CameraExtensionStreamSource.swift          // extracted unchanged
    CameraExtensionProviderSource.swift        // provider + notifications (kept together)
  DeviceFeatures/
    CameraExtensionDeviceSource+CaptureSession.swift  // start/stop, heartbeat, setup/switch, interruptions  
    CameraExtensionDeviceSource+FramePipeline.swift   // frame generation, overlays, splash, AVCapture delegate
  CameraExtensionDiagnostics.swift            // diagnostic system (UNCHANGED)
  CameraExtensionErrorManager.swift           // error handling (UNCHANGED)
  CameraExtensionPerformanceManager.swift     // performance monitoring (UNCHANGED)
  Rendering/
    CameraOverlayRenderer.swift               // overlay rendering (UNCHANGED)
  main.swift                                   // entry point (UNCHANGED)
  CameraExtension.entitlements                // system permissions (UNCHANGED)
  Info.plist                                   // bundle info (UNCHANGED)
  Support/ (optional)
    CameraExtensionSupport.swift               // kFrameRate, logger, tiny helpers

Migration steps (3 small commits):

	1.	Create folder structure and extract core classes
	•	Create Core/ and DeviceFeatures/ folders
	•	Extract CameraExtensionStreamSource and CameraExtensionProviderSource from CameraExtensionProvider.swift into Core/ unchanged
	•	Keep CameraExtensionDeviceSource in Core/CameraExtensionDeviceSource.swift with core properties and init
	•	Build & smoke test - all classes now exist in separate files
	
	2.	Add +CaptureSession extension
	•	Create DeviceFeatures/CameraExtensionDeviceSource+CaptureSession.swift
	•	Move capture session related methods: startStreaming/stopStreaming, startAppControlledStreaming/stopAppControlledStreaming, startCameraCapture/stopCameraCapture, heartbeat timers (startHeartbeatTimer/stopHeartbeatTimer), setupCaptureSession, setCameraDevice, findDeviceByID, getCurrentDeviceName, and interruption handlers (captureSessionWasInterrupted/captureSessionInterruptionEnded)
	•	Build & verify start/stop behavior and device switching
	
	3.	Add +FramePipeline extension  
	•	Create DeviceFeatures/CameraExtensionDeviceSource+FramePipeline.swift
	•	Move frame rendering methods: generateVirtualCameraFrame, drawOverlaysWithPresetSystem, drawSplashScreen, createCGImage, captureOutput(_:didOutput:from:), loadOverlaySettings, updateOverlaySettings, cacheCameraDimensions
	•	Build & verify overlays/splash and live frames work correctly

Guardrail: if any private member blocks same-file extension access, change just that member to fileprivate (no signature/behavior changes).

Desired outcome (acceptance criteria)
	•	No functional regressions
	•	Virtual camera enumerates and streams in Meet/Zoom as before.
	•	External start/stop and app-controlled start/stop behave identically.
	•	Camera indicator turns off when leaving a meeting.
	•	Device switching via Darwin notification still works.
	•	Overlays render; splash shows when expected.
	•	Heartbeat logs keep ticking on a 2s cadence.
	•	Review & debug are simpler
	•	To understand start/stop or device switching, open +CaptureSession.swift only.
	•	To understand frame rendering or overlays, open +FramePipeline.swift only.
	•	Provider lifecycle and notifications live together in one file.
	•	Grepping “startStreaming” or “overlay” lands you in the right concern file.
	•	Code organization stays lightweight
	•	Total files ≤ 7; only two adjunct files for the large class.
	•	No public API or method signature changes.
	•	Log messages unchanged (easy runtime diffing).

Testing checklist (run after each commit)
	•	Build extension target successfully.
	•	Stream start/stop from Meet/Zoom works; indicator light correct.
	•	App menu start/stop works; status updates written as before.
	•	Device switch via notification takes effect (check logs + video).
	•	Overlay toggles/changes are reflected; splash appears when no frame.
	•	Heartbeat logs continue every ~2s while active.

Risks & mitigations
	•	Risk: Access-control friction when moving methods.
Mitigation: Use fileprivate on specific members; keep everything in the same target.
	•	Risk: Subtle init order regressions.
Mitigation: Keep init(localizedName:) body exactly as-is and in the root file; don’t reorder.
	•	Risk: Reviewer confusion.
Mitigation: Add // MARK: sections and a short header comment atop each new file:
"Extracted from CameraExtensionProvider.swift on YYYY-MM-DD. No functional changes."

Rollback plan

Each commit is mechanical. If anything misbehaves, revert the last commit and you’re back to a known-good state without touching logic.
