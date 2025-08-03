//
//  CustomPropertyManager.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import Foundation
import SwiftUI
import AVFoundation
import CoreMediaIO
import OSLog

class CustomPropertyManager: NSObject, ObservableObject {
    // MARK: Lifecycle
    
    override init() {
        super.init()
        effect = MoodName(rawValue: getPropertyValue(withSelectorName: mood) ?? MoodName.bypass.rawValue) ?? MoodName.bypass
    }
    
    // MARK: Internal
    
    let mood = PropertyName.mood.rawValue.convertedToCMIOObjectPropertySelectorName()
    var effect: MoodName = .bypass
    
    lazy var deviceObjectID: CMIOObjectID? = {
        let device = getExtensionDevice(name: "Headliner")
        if let device = device, let deviceObjectId = getCMIODeviceID(fromUUIDString: device.uniqueID) {
            return deviceObjectId
        }
        return nil
        
    }()
    
    func getExtensionDevice(name: String) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera],
                                                                mediaType: .video,
                                                                position: .unspecified)
        return discoverySession.devices.first { $0.localizedName == name }
    }
    
    func propertyExists(inDeviceAtID deviceID: CMIODeviceID, withSelectorName selectorName: CMIOObjectPropertySelector) -> CMIOObjectPropertyAddress? {
        var address = CMIOObjectPropertyAddress(mSelector: CMIOObjectPropertySelector(selectorName), mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal), mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
        let exists = CMIOObjectHasProperty(deviceID, &address)
        return exists ? address : nil
    }
    
    func getCMIODeviceID(fromUUIDString uuidString: String) -> CMIOObjectID? {
        var propertyDataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        var cmioObjectPropertyAddress = CMIOObjectPropertyAddress(mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices), mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal), mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
        CMIOObjectGetPropertyDataSize(CMIOObjectPropertySelector(kCMIOObjectSystemObject), &cmioObjectPropertyAddress, 0, nil, &propertyDataSize)
        let count = Int(propertyDataSize) / MemoryLayout<CMIOObjectID>.size
        var cmioDevices = [CMIOObjectID](repeating: 0, count: count)
        CMIOObjectGetPropertyData(CMIOObjectPropertySelector(kCMIOObjectSystemObject), &cmioObjectPropertyAddress, 0, nil, propertyDataSize, &dataUsed, &cmioDevices)
        for deviceObjectID in cmioDevices {
            cmioObjectPropertyAddress.mSelector = CMIOObjectPropertySelector(kCMIODevicePropertyDeviceUID)
            CMIOObjectGetPropertyDataSize(deviceObjectID, &cmioObjectPropertyAddress, 0, nil, &propertyDataSize)
            var deviceNameBuffer = [CChar](repeating: 0, count: Int(propertyDataSize))
            CMIOObjectGetPropertyData(deviceObjectID, &cmioObjectPropertyAddress, 0, nil, propertyDataSize, &dataUsed, &deviceNameBuffer)

            let deviceName = String(cString: deviceNameBuffer)
            if deviceName == uuidString {
                return deviceObjectID
            }
        }
        return nil
    }
    
    func getPropertyValue(withSelectorName selectorName: CMIOObjectPropertySelector) -> String? {
        var propertyAddress = CMIOObjectPropertyAddress(mSelector: CMIOObjectPropertySelector(selectorName), mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal), mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
        
        guard let deviceID = deviceObjectID else {
            logger.error("Couldn't get object ID, returning")
            return nil
        }
        
        if CMIOObjectHasProperty(deviceID, &propertyAddress) {
            var propertyDataSize: UInt32 = 0
            CMIOObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &propertyDataSize)
            
            var dataUsed: UInt32 = 0
            var buffer = [CChar](repeating: 0, count: Int(propertyDataSize))
            CMIOObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, propertyDataSize, &dataUsed, &buffer)

            return String(cString: buffer)
        }
        return nil
    }
    func setPropertyValue(withSelectorName selectorName: CMIOObjectPropertySelector, to value: String) -> Bool {
        guard let deviceID = deviceObjectID, var propertyAddress = propertyExists(inDeviceAtID: deviceID, withSelectorName: selectorName) else {
            logger.debug("Property doesn't exist")
            return false
        }
        var settable: DarwinBoolean = false
        CMIOObjectIsPropertySettable(deviceID, &propertyAddress, &settable)
        if settable == false {
            logger.debug("Property can't be set")
            return false
        }
        var dataSize: UInt32 = 0
        CMIOObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &dataSize)
        let valueString: CFString = value as CFString
        let result = withUnsafePointer(to: valueString) { ptr in
            return CMIOObjectSetPropertyData(deviceID, &propertyAddress, 0, nil, UInt32(MemoryLayout<CFString>.size), ptr)
        }
        if result != 0 {
            logger.debug("Not successful setting property data")
            return false
        }
        return true
    }
}