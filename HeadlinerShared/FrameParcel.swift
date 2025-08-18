//
//  FrameParcel.swift
//  HeadlinerShared
//
//  NSSecureCoding-compliant container for transporting IOSurface via mach port
//

import Foundation
import CoreMedia
import IOSurface

/// Secure container for frame metadata and mach port transport
@objc final class FrameParcel: NSObject, NSSecureCoding {
    
    // MARK: - NSSecureCoding
    
    static var supportsSecureCoding: Bool = true
    
    // MARK: - Properties
    
    /// Mach port send right for the IOSurface
    let machPort: mach_port_t
    
    /// Frame dimensions
    let width: Int32
    let height: Int32
    
    /// Pixel format (FourCC)
    let pixelFormat: OSType
    
    /// Monotonic frame counter
    let frameIndex: Int64
    
    /// Presentation timestamp numerator
    let ptsNum: Int64
    
    /// Presentation timestamp denominator
    let ptsDen: Int32
    
    /// Color space identifier (e.g., "ITU_R_709_2", "sRGB", "Display-P3")
    let colorSpaceName: String
    
    // MARK: - Initialization
    
    init(machPort: mach_port_t,
         width: Int32,
         height: Int32,
         pixelFormat: OSType,
         frameIndex: Int64,
         ptsNum: Int64,
         ptsDen: Int32,
         colorSpaceName: String) {
        self.machPort = machPort
        self.width = width
        self.height = height
        self.pixelFormat = pixelFormat
        self.frameIndex = frameIndex
        self.ptsNum = ptsNum
        self.ptsDen = ptsDen
        self.colorSpaceName = colorSpaceName
        super.init()
    }
    
    // MARK: - NSCoding
    
    private enum CodingKeys: String {
        case machPort
        case width
        case height
        case pixelFormat
        case frameIndex
        case ptsNum
        case ptsDen
        case colorSpaceName
    }
    
    required init?(coder: NSCoder) {
        // Decode mach port as UInt32
        self.machPort = coder.decodeObject(of: NSNumber.self, forKey: CodingKeys.machPort.rawValue)?.uint32Value ?? 0
        
        // Decode dimensions
        self.width = coder.decodeObject(of: NSNumber.self, forKey: CodingKeys.width.rawValue)?.int32Value ?? 0
        self.height = coder.decodeObject(of: NSNumber.self, forKey: CodingKeys.height.rawValue)?.int32Value ?? 0
        
        // Decode pixel format
        self.pixelFormat = coder.decodeObject(of: NSNumber.self, forKey: CodingKeys.pixelFormat.rawValue)?.uint32Value ?? 0
        
        // Decode frame counter
        self.frameIndex = coder.decodeObject(of: NSNumber.self, forKey: CodingKeys.frameIndex.rawValue)?.int64Value ?? 0
        
        // Decode PTS
        self.ptsNum = coder.decodeObject(of: NSNumber.self, forKey: CodingKeys.ptsNum.rawValue)?.int64Value ?? 0
        self.ptsDen = coder.decodeObject(of: NSNumber.self, forKey: CodingKeys.ptsDen.rawValue)?.int32Value ?? 1
        
        // Decode color space
        self.colorSpaceName = coder.decodeObject(of: NSString.self, forKey: CodingKeys.colorSpaceName.rawValue) as String? ?? "sRGB"
        
        super.init()
    }
    
    func encode(with coder: NSCoder) {
        // Encode mach port as NSNumber
        coder.encode(NSNumber(value: machPort), forKey: CodingKeys.machPort.rawValue)
        
        // Encode dimensions
        coder.encode(NSNumber(value: width), forKey: CodingKeys.width.rawValue)
        coder.encode(NSNumber(value: height), forKey: CodingKeys.height.rawValue)
        
        // Encode pixel format
        coder.encode(NSNumber(value: pixelFormat), forKey: CodingKeys.pixelFormat.rawValue)
        
        // Encode frame counter
        coder.encode(NSNumber(value: frameIndex), forKey: CodingKeys.frameIndex.rawValue)
        
        // Encode PTS
        coder.encode(NSNumber(value: ptsNum), forKey: CodingKeys.ptsNum.rawValue)
        coder.encode(NSNumber(value: ptsDen), forKey: CodingKeys.ptsDen.rawValue)
        
        // Encode color space
        coder.encode(colorSpaceName as NSString, forKey: CodingKeys.colorSpaceName.rawValue)
    }
    
    // MARK: - Helpers
    
    /// Create CMTime from PTS values
    var presentationTimeStamp: CMTime {
        return CMTime(value: ptsNum, timescale: ptsDen)
    }
    
    /// Get CoreGraphics color space from name
    var cgColorSpace: CGColorSpace? {
        switch colorSpaceName {
        case "sRGB":
            return CGColorSpace(name: CGColorSpace.sRGB)
        case "Display-P3":
            return CGColorSpace(name: CGColorSpace.displayP3)
        case "ITU_R_709_2", "Rec709":
            return CGColorSpace(name: CGColorSpace.itur_709)
        default:
            return CGColorSpace(name: CGColorSpace.sRGB)
        }
    }
    
    /// Get color space identifier for Core Video
    var cvColorSpace: CFString {
        switch colorSpaceName {
        case "ITU_R_709_2", "Rec709":
            return kCVImageBufferYCbCrMatrix_ITU_R_709_2
        case "Display-P3":
            return kCVImageBufferColorPrimaries_DCI_P3 
        default:
            return kCVImageBufferColorPrimaries_ITU_R_709_2
        }
    }
}

