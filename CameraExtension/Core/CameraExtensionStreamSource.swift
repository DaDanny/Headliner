//
//  CameraExtensionStreamSource.swift
//  CameraExtension
//
//  Extracted from CameraExtensionProvider.swift on 2025-01-28. No functional changes.
//

import Foundation
import CoreMediaIO
import OSLog

// MARK: - Shared Constants and Logger

let kFrameRate: Int = 60
private let extensionLogger = Logger(subsystem: "com.dannyfrancken.Headliner", category: "Extension")

// MARK: - CameraExtensionStreamSource

class CameraExtensionStreamSource: NSObject, CMIOExtensionStreamSource {
	
	private(set) var stream: CMIOExtensionStream!
	
	let device: CMIOExtensionDevice
	
	private let _streamFormat: CMIOExtensionStreamFormat
	
	init(localizedName: String, streamID: UUID, streamFormat: CMIOExtensionStreamFormat, device: CMIOExtensionDevice) {
		
		self.device = device
		self._streamFormat = streamFormat
		super.init()
		self.stream = CMIOExtensionStream(localizedName: localizedName, streamID: streamID, direction: .source, clockType: .hostTime, source: self)
	}
	
	var formats: [CMIOExtensionStreamFormat] {
		
		return [_streamFormat]
	}
	
	var activeFormatIndex: Int = 0 {
		
		didSet {
			if activeFormatIndex >= 1 {
				extensionLogger.error("Invalid index")
			}
		}
	}
	
	var availableProperties: Set<CMIOExtensionProperty> {
		
		return [.streamActiveFormatIndex, .streamFrameDuration]
	}
	
	func streamProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionStreamProperties {
		
		let streamProperties = CMIOExtensionStreamProperties(dictionary: [:])
		if properties.contains(.streamActiveFormatIndex) {
			streamProperties.activeFormatIndex = 0
		}
		if properties.contains(.streamFrameDuration) {
			let frameDuration = CMTime(value: 1, timescale: Int32(kFrameRate))
			streamProperties.frameDuration = frameDuration
		}
		
		return streamProperties
	}
	
	func setStreamProperties(_ streamProperties: CMIOExtensionStreamProperties) throws {
		
		if let activeFormatIndex = streamProperties.activeFormatIndex {
			self.activeFormatIndex = activeFormatIndex
		}
	}
	
	func authorizedToStartStream(for client: CMIOExtensionClient) -> Bool {
		extensionLogger.debug("External app requesting stream authorization: \(client.clientID)")
		// An opportunity to inspect the client info and decide if it should be allowed to start the stream.
		return true
	}
	
	func startStream() throws {
		extensionLogger.debug("External app starting virtual camera stream")
		guard let deviceSource = device.source as? CameraExtensionDeviceSource else {
			fatalError("Unexpected source type \(String(describing: device.source))")
		}
		deviceSource.startStreaming()
	}
	
	func stopStream() throws {
		extensionLogger.debug("External app stopping virtual camera stream")
		guard let deviceSource = device.source as? CameraExtensionDeviceSource else {
			fatalError("Unexpected source type \(String(describing: device.source))")
		}
		deviceSource.stopStreaming()
	}
}