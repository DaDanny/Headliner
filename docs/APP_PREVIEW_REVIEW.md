# Live In-App Preview - Code Review & Implementation Status

## Executive Summary

The Live In-App Preview feature is **NOT WORKING** despite all implementation files being properly included in the Xcode project. The build successfully compiles:

1. **FrameSharingService.swift** (Camera Extension) - ✅ IN PROJECT & COMPILING
2. **FrameClient.swift** (Main App) - ✅ IN PROJECT & COMPILING
3. **LivePreviewLayer.swift** (Main App) - ✅ IN PROJECT & COMPILING

The issue lies elsewhere - there are security vulnerabilities and implementation gaps that need to be addressed.

## Critical Issues Found

### 1. XPC Connection Not Establishing (**BLOCKING**)

Despite all files being properly included and compiling, the live preview is not working. Possible causes:

- XPC service may not be starting correctly
- Mach service name mismatch between client and server
- Sandbox restrictions preventing connection
- Darwin notifications not being received

**Debugging needed**: Check Console.app for XPC connection errors and sandbox violations.

### 2. Security Vulnerability (**HIGH PRIORITY**)

Location: `CameraExtension/FrameSharingService.swift:247`

```swift
private func validateConnection(_ connection: NSXPCConnection) -> Bool {
    // Get audit token to validate client
    var token = audit_token_t()
    connection.auditToken(&token)

    // ...comments about what should be validated...

    return true  // TODO: Implement proper validation
}
```

**Issue**: ANY process can connect to the XPC service and retrieve camera frames.

Location: `CameraExtension/FrameSharingService.swift:273-278`

```swift
func auditToken(_ token: inout audit_token_t) {
    // This would use private API in production
    // For now, we'll use a placeholder
    // In real implementation, use:
    // xpc_connection_get_audit_token(self._xpcConnection, &token)
}
```

**Issue**: The audit token retrieval is stubbed and doesn't actually work.

### 3. Conditional Logic Issue

Location: `Headliner/Views/Components/CameraPreviewCard.swift:22-26`

```swift
if isExtensionRunning {
    LivePreviewLayer(isActive: .constant(isActive))
    ...
}
```

The condition checks `appState.extensionStatus == .installed`, but this only verifies installation, not that the extension is actively running. The LivePreviewLayer will try to connect even when the extension isn't streaming.

## Implementation Status by Component

### ✅ Properly Included in Xcode Project:

- `HeadlinerShared/FrameParcel.swift` - Both targets ✓
- `HeadlinerShared/FrameSharingProtocol.swift` - Both targets ✓
- `CameraExtension/FrameSharingService.swift` - Extension target ✓
- `Headliner/Preview/FrameClient.swift` - Main app target ✓
- `Headliner/Views/Components/LivePreviewLayer.swift` - Main app target ✓
- Entitlements configured correctly ✓
- Darwin notifications setup ✓

### ⚠️ Code Issues Found:

#### TODOs and Stubs:

1. **Security validation stub** - `FrameSharingService.swift:247`
2. **Audit token placeholder** - `FrameSharingService.swift:273-278`

#### No Other Critical TODOs Found:

- FrameClient.swift - Clean (but not in project)
- LivePreviewLayer.swift - Clean (but not in project)
- FrameParcel.swift - Clean
- FrameSharingProtocol.swift - Clean

## Recommendations for MVP Release

### Immediate Actions Required (Blocking):

1. **Debug XPC Connection Issue**:

   - Check Console.app for sandbox violations or XPC errors
   - Verify mach service name matches: `378NGS49HA.com.dannyfrancken.Headliner.frameshare`
   - Test if XPC service is actually starting
   - Verify Darwin notifications are being sent/received

2. **Fix Security Validation** (Minimal MVP Version):

   ```swift
   private func validateConnection(_ connection: NSXPCConnection) -> Bool {
       // MVP: At minimum, check process identifier matches our app
       let pid = connection.processIdentifier

       // Get our main app's process name
       if let processInfo = ProcessInfo.processInfo.environment["__CFBundleIdentifier"],
          processInfo.hasPrefix("com.dannyfrancken.Headliner") {
           return true
       }

       logger.error("Rejecting connection from unknown process: \(pid)")
       return false
   }
   ```

3. **Fix Extension Running Detection**:
   Change the condition in CameraPreviewCard to check if the camera is actually streaming:
   ```swift
   // Instead of: isExtensionRunning: appState.extensionStatus == .installed
   // Use: isExtensionRunning: appState.extensionStatus == .installed && appState.cameraStatus.isRunning
   ```

### Nice-to-Have for MVP:

1. **Add Connection Status UI**:

   - Show "Connecting..." state in preview
   - Show "Extension Not Running" when appropriate
   - Add retry button if connection fails

2. **Add Basic Telemetry**:

   - Log frame drops
   - Log connection failures
   - Track average latency

3. **Improve Error Messages**:
   - User-friendly error when extension isn't running
   - Clear message if permissions are missing

## Remaining Work Not Documented

### Build & Integration:

1. Clean build after adding files to Xcode
2. Test XPC connection establishment
3. Verify Darwin notifications are being received
4. Check Console.app for sandbox violations

### Testing Required:

1. Test with camera actually running
2. Test start/stop cycles
3. Test resolution changes
4. Test extension crash recovery
5. Test with different cameras

### Debugging Steps:

Since the preview isn't updating when camera starts:

1. **Check Logs**:

   ```bash
   # Watch for XPC connection logs
   log stream --predicate 'subsystem == "com.dannyfrancken.Headliner"'

   # Check for sandbox violations
   log stream --predicate 'eventMessage CONTAINS "sandbox"'
   ```

2. **Verify Mach Service**:

   ```bash
   # Check if service is registered
   launchctl list | grep frameshare
   ```

3. **Debug Connection**:
   - Add logging to FrameSharingService init
   - Add logging to FrameClient connection attempts
   - Verify notifications are being posted/received

## Documentation Updates Needed

The `docs/APP_PREVIEW.md` file needs the following corrections:

1. **Section: Xcode Project Configuration**

   - Update to reflect that THREE files need to be added, not just FrameParcel.swift
   - Add explicit file paths for all three missing files

2. **Section: Security Considerations**

   - Remove "Basic connection validation via audit token" - it's not implemented
   - Add warning about current security vulnerability

3. **Section: Implementation Status**

   - Update to reflect files are NOT in Xcode project
   - Mark security validation as NOT completed

4. **Section: Testing Checklist**
   - These items cannot be marked as complete since the feature doesn't work

## Summary

The Live In-App Preview feature has solid architecture and complete implementation with all files properly included in Xcode, but it's **not working** due to:

1. **XPC connection not establishing** - Most likely cause of preview not updating
2. **Security validation is completely stubbed** - Any app could connect and steal frames
3. **The UI shows LivePreviewLayer even when extension isn't streaming**

**Estimated time to fix for MVP**: 1-3 hours

- 30-60 minutes to debug XPC connection issues
- 30 minutes to implement basic security validation
- 30 minutes to test and verify functionality
- 15 minutes to update documentation

Since all files are properly included and compiling, the issue is likely a runtime configuration problem (sandbox, entitlements, or mach service naming).
