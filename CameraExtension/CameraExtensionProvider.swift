//
//  CameraExtensionProvider.swift
//  CameraExtension
//
//  Created by Danny Francken on 8/2/25.
//

import Foundation
import CoreMediaIO
import IOKit.audio
import os.log
import AVFoundation

let kWhiteStripeHeight: Int = 10
let kFrameRate: Int = 60


let logger = Logger(subsystem: "com.dannyfrancken.headliner",
                    category: "Extension")

// MARK: - ExtensionDeviceSourceDelegate

// MARK: -

class CameraExtensionDeviceSource: NSObject, CMIOExtensionDeviceSource, AVCaptureVideoDataOutputSampleBufferDelegate {
	
	private(set) var device: CMIOExtensionDevice!
	
	private var _streamSource: CameraExtensionStreamSource!
	
	private var _streamingCounter: UInt32 = 0
	
	private var _videoDescription: CMFormatDescription!
	
	private var _bufferPool: CVPixelBufferPool!
	
	private var _bufferAuxAttributes: NSDictionary!
	
	// Camera capture components
	private var captureSession: AVCaptureSession?
	private var videoOutput: AVCaptureVideoDataOutput?
	private var currentInput: AVCaptureDeviceInput?
	private let captureQueue = DispatchQueue(label: "CameraCaptureQueue", qos: .userInteractive)
	private var selectedCameraDevice: AVCaptureDevice?
	
	init(localizedName: String) {
		
		super.init()
		let deviceID = UUID() // replace this with your device UUID
		self.device = CMIOExtensionDevice(localizedName: localizedName, deviceID: deviceID, legacyDeviceID: nil, source: self)
		
		let dims = CMVideoDimensions(width: 1920, height: 1080)
		CMVideoFormatDescriptionCreate(allocator: kCFAllocatorDefault, codecType: kCVPixelFormatType_32BGRA, width: dims.width, height: dims.height, extensions: nil, formatDescriptionOut: &_videoDescription)
		
		let pixelBufferAttributes: NSDictionary = [
			kCVPixelBufferWidthKey: dims.width,
			kCVPixelBufferHeightKey: dims.height,
			kCVPixelBufferPixelFormatTypeKey: _videoDescription.mediaSubType,
			kCVPixelBufferIOSurfacePropertiesKey: [:] as NSDictionary
		]
		CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, pixelBufferAttributes, &_bufferPool)
		
		let videoStreamFormat = CMIOExtensionStreamFormat.init(formatDescription: _videoDescription, maxFrameDuration: CMTime(value: 1, timescale: Int32(kFrameRate)), minFrameDuration: CMTime(value: 1, timescale: Int32(kFrameRate)), validFrameDurations: nil)
		_bufferAuxAttributes = [kCVPixelBufferPoolAllocationThresholdKey: 5]
		
		let videoID = UUID() // replace this with your video UUID
		_streamSource = CameraExtensionStreamSource(localizedName: "Headliner.Video", streamID: videoID, streamFormat: videoStreamFormat, device: device)
		do {
			try device.addStream(_streamSource.stream)
		} catch let error {
			fatalError("Failed to add stream: \(error.localizedDescription)")
		}
	}
	
	var availableProperties: Set<CMIOExtensionProperty> {
		
		return [.deviceTransportType, .deviceModel]
	}
	
	func deviceProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties {
		
		let deviceProperties = CMIOExtensionDeviceProperties(dictionary: [:])
		if properties.contains(.deviceTransportType) {
			deviceProperties.transportType = kIOAudioDeviceTransportTypeVirtual
		}
		if properties.contains(.deviceModel) {
			deviceProperties.model = "Headliner Model"
		}
		
		return deviceProperties
	}
	
	func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws {
		
		// Handle settable properties here.
	}
	
	func startStreaming() {
		guard let captureSession = captureSession else {
			logger.error("No capture session available")
			return
		}
		
		_streamingCounter += 1
		
		if !captureSession.isRunning {
			captureQueue.async {
				captureSession.startRunning()
				logger.debug("Started camera capture session")
			}
		}
	}
	
	func stopStreaming() {
		if _streamingCounter > 1 {
			_streamingCounter -= 1
		} else {
			_streamingCounter = 0
			if let captureSession = captureSession, captureSession.isRunning {
				captureQueue.async {
					captureSession.stopRunning()
					logger.debug("Stopped camera capture session")
				}
			}
		}
	}
	
	// MARK: Camera Setup
	
	private func setupCaptureSession() {
		captureSession = AVCaptureSession()
		guard let captureSession = captureSession else { return }
		
		captureSession.sessionPreset = .hd1280x720
		
		// Setup video output
		videoOutput = AVCaptureVideoDataOutput()
		guard let videoOutput = videoOutput else { return }
		
		videoOutput.setSampleBufferDelegate(self, queue: captureQueue)
		videoOutput.videoSettings = [
			kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
		]
		
		if captureSession.canAddOutput(videoOutput) {
			captureSession.addOutput(videoOutput)
		}
		
		// Use default camera initially
		setupCameraInput()
	}
	
	private func setupCameraInput() {
		guard let captureSession = captureSession else { return }
		
		// Remove existing input
		if let currentInput = currentInput {
			captureSession.removeInput(currentInput)
		}
		
		// Get default camera device
		let defaultCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ??
							AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) ??
							AVCaptureDevice.default(for: .video)
		
		guard let camera = selectedCameraDevice ?? defaultCamera else {
			logger.error("No camera device available")
			return
		}
		
		do {
			let input = try AVCaptureDeviceInput(device: camera)
			if captureSession.canAddInput(input) {
				captureSession.addInput(input)
				currentInput = input
				logger.debug("Added camera input: \(camera.localizedName)")
			}
		} catch {
			logger.error("Failed to create camera input: \(error.localizedDescription)")
		}
	}
	
	func setCameraDevice(_ deviceID: String) {
		// Find camera device by unique ID
		let discoverySession = AVCaptureDevice.DiscoverySession(
			deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera, .deskViewCamera],
			mediaType: .video,
			position: .unspecified
		)
		
		selectedCameraDevice = discoverySession.devices.first { $0.uniqueID == deviceID }
		
		// Reconfigure input if streaming
		if _streamingCounter > 0 {
			setupCameraInput()
		}
	}
	
	// MARK: AVCaptureVideoDataOutputSampleBufferDelegate
	
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		// Get the pixel buffer from the sample buffer
		guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			logger.error("Failed to get pixel buffer from sample buffer")
			return
		}
		
		// Create a new sample buffer with the correct format description
		var newSampleBuffer: CMSampleBuffer?
		var timingInfo = CMSampleTimingInfo()
		timingInfo.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock())
		timingInfo.decodeTimeStamp = CMTime.invalid
		timingInfo.duration = CMTime.invalid
		
		let result = CMSampleBufferCreateReadyWithImageBuffer(
			allocator: kCFAllocatorDefault,
			imageBuffer: pixelBuffer,
			formatDescription: _videoDescription,
			sampleTiming: &timingInfo,
			sampleBufferOut: &newSampleBuffer
		)
		
		if result == noErr, let sampleBuffer = newSampleBuffer {
			// Send the frame to the virtual camera stream
			_streamSource.stream.send(
				sampleBuffer,
				discontinuity: [],
				hostTimeInNanoseconds: UInt64(timingInfo.presentationTimeStamp.seconds * Double(NSEC_PER_SEC))
			)
		} else {
			logger.error("Failed to create sample buffer for virtual camera: \(result)")
		}
	}
}

// MARK: -

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
				os_log(.error, "Invalid index")
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
		
		// An opportunity to inspect the client info and decide if it should be allowed to start the stream.
		return true
	}
	
	func startStream() throws {
		
		guard let deviceSource = device.source as? CameraExtensionDeviceSource else {
			fatalError("Unexpected source type \(String(describing: device.source))")
		}
		deviceSource.startStreaming()
	}
	
	func stopStream() throws {
		
		guard let deviceSource = device.source as? CameraExtensionDeviceSource else {
			fatalError("Unexpected source type \(String(describing: device.source))")
		}
		deviceSource.stopStreaming()
	}
}

// MARK: -

class CameraExtensionProviderSource: NSObject, CMIOExtensionProviderSource {
	
	private(set) var provider: CMIOExtensionProvider!
	
	private var deviceSource: CameraExtensionDeviceSource!
    
    private let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
    private var notificationListenerStarted = false
	
	// CMIOExtensionProviderSource protocol methods (all are required)
	
	init(clientQueue: DispatchQueue?) {
		
		super.init()
        startNotificationListeners()
        
		provider = CMIOExtensionProvider(source: self, clientQueue: clientQueue)
		deviceSource = CameraExtensionDeviceSource(localizedName: "Headliner")
		
		do {
			try provider.addDevice(deviceSource.device)
		} catch let error {
			fatalError("Failed to add device: \(error.localizedDescription)")
		}
	}
    
    deinit {
        stopNotificationListeners()
    }
	
    // MARK: Internal
    
	func connect(to client: CMIOExtensionClient) throws {
		
		// Handle client connect
	}
	
	func disconnect(from client: CMIOExtensionClient) {
		
		// Handle client disconnect
	}
	
	var availableProperties: Set<CMIOExtensionProperty> {
		
		// See full list of CMIOExtensionProperty choices in CMIOExtensionProperties.h
		return [.providerManufacturer]
	}
	
	func providerProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties {
		
		let providerProperties = CMIOExtensionProviderProperties(dictionary: [:])
		if properties.contains(.providerManufacturer) {
			providerProperties.manufacturer = "Headliner Manufacturer"
		}
		return providerProperties
	}
	
	func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {
		
		// Handle settable properties here.
	}
    
    // MARK: Private
    
    private func notificationReceived(notificationName: String) {
        guard let name = NotificationName(rawValue: notificationName) else {
            return
        }

        switch name {
        case .startStream:
            logger.debug("Starting camera stream")
            deviceSource.startStreaming()
        case .stopStream:
            logger.debug("Stopping camera stream")
            deviceSource.stopStreaming()
        case .setCameraDevice:
            logger.debug("Camera device selection changed")
            handleCameraDeviceChange()
        }
    }

    private func startNotificationListeners() {
        for notificationName in NotificationName.allCases {
            let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())

            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), observer, { _, observer, name, _, _ in
                if let observer = observer, let name = name {
                    let extensionProviderSourceSelf = Unmanaged<CameraExtensionProviderSource>.fromOpaque(observer).takeUnretainedValue()
                    extensionProviderSourceSelf.notificationReceived(notificationName: name.rawValue as String)
                }
            },
            notificationName.rawValue as CFString, nil, .deliverImmediately)
        }
    }

    private func stopNotificationListeners() {
        if notificationListenerStarted {
            CFNotificationCenterRemoveEveryObserver(notificationCenter,
                                                    Unmanaged.passRetained(self)
                                                        .toOpaque())
            notificationListenerStarted = false
        }
    }
    
    private func handleCameraDeviceChange() {
        // Read camera device ID from UserDefaults
        if let userDefaults = UserDefaults(suiteName: "378NGS49HA.com.dannyfrancken.Headliner"),
           let deviceID = userDefaults.string(forKey: "SelectedCameraID") {
            logger.debug("Setting camera device to: \(deviceID)")
            deviceSource.setCameraDevice(deviceID)
        }
    }
}
