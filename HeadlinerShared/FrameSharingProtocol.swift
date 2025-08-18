//
//  FrameSharingProtocol.swift
//  HeadlinerShared
//
//  XPC protocol for zero-copy frame sharing between extension and main app
//

import Foundation

/// Protocol defining the NSXPC service interface for frame sharing
/// Note: FrameParcel must be imported separately or be in the same module
@objc protocol FrameSharingProtocol {
    /// Fetch the latest composed frame parcel
    /// Returns nil if no frame is available
    func getLatestFrame(reply: @escaping (FrameParcel?) -> Void)
}

/// Mach service name for the XPC connection
struct FrameSharingConstants {
    // Use team ID prefix to match notification naming and ensure proper sandboxing
    static let machServiceName = "\(Identifiers.teamID).com.dannyfrancken.Headliner.frameshare"
}
