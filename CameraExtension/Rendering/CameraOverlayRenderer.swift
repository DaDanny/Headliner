//
//  CameraOverlayRenderer.swift
//  CameraExtension
//
//  Thread-safe overlay renderer for the camera extension using Core frameworks only.
//  This implementation avoids AppKit to ensure thread safety and optimal performance
//  in the sandboxed camera extension environment.
//

import CoreImage
import CoreVideo
import CoreGraphics
import CoreText
import Metal
import QuartzCore

// MARK: - Camera Overlay Renderer

/// Thread-safe overlay renderer for camera extension.
///
/// This renderer uses only Core frameworks (CoreImage, CoreGraphics, CoreText) to ensure
/// thread safety and optimal performance. It avoids AppKit which is not thread-safe and
/// can cause issues in camera extensions that run in separate processes.
///
/// Key features:
/// - Metal-backed CIContext for GPU acceleration
/// - LRU cache for rendered overlays to avoid redundant work
/// - Smooth crossfade transitions between aspect ratios
/// - Deterministic cache keys for stable performance
/// - sRGB color management throughout the pipeline
final class CameraOverlayRenderer: OverlayRenderer {
    
    // MARK: - Properties
    
    /// Serial queue for thread-safe cache access
    private let cacheQueue = DispatchQueue(label: "CameraOverlayRenderer.cache")
    
    /// Core Image context for GPU-accelerated rendering
    private let ciContext: CIContext
    
    /// sRGB color space used throughout the rendering pipeline for consistency
    private let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    
    /// Previous overlay image used for smooth crossfade transitions
    private var previousOverlay: CIImage?
    
    /// Timestamp when crossfade animation started
    private var crossfadeStart: CFTimeInterval?
    
    /// Duration of crossfade animation in seconds
    private let crossfadeDuration: CFTimeInterval = 0.25
    
    /// Deterministic cache key for overlay layouts.
    /// Uses consolidated token signature for comprehensive invalidation.
    struct LayoutKey: Hashable {
        let presetID: String
        let aspect: String
        let signature: String
        
        static func == (lhs: LayoutKey, rhs: LayoutKey) -> Bool {
            return lhs.presetID == rhs.presetID &&
                   lhs.aspect == rhs.aspect &&
                   lhs.signature == rhs.signature
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(presetID)
            hasher.combine(aspect)
            hasher.combine(signature)
        }
    }
    
    /// LRU cache for rendered overlay images to avoid redundant rendering
    private var cache = LRUCache<LayoutKey, CIImage>(capacity: 6)  // Reduced for MVP memory footprint
    
    /// Reader for personal information from App Group storage
    private let personalInfoReader = PersonalInfoReader()
    
    /// Track last layout key to detect content changes for crossfade
    private var lastKey: LayoutKey?

    // MARK: - Initialization
    
    init() {
        // Metal-first approach for best performance
        if let device = MTLCreateSystemDefaultDevice() {
            self.ciContext = CIContext(
                mtlDevice: device,
                options: [
                    .workingColorSpace: colorSpace,
                    .outputColorSpace: colorSpace,
                    .priorityRequestLow: false,
                    .cacheIntermediates: true
                ]
            )
        } else {
            // CPU fallback when Metal is unavailable
            self.ciContext = CIContext(options: [
                .workingColorSpace: colorSpace,
                .outputColorSpace: colorSpace,
                .useSoftwareRenderer: true
            ])
        }
        
        // PersonalInfoReader reads from App Group storage
    }
    
    // MARK: - Public Methods
    
    func render(pixelBuffer: CVPixelBuffer,
                preset: OverlayPreset,
                tokens: OverlayTokens,
                previousFrame: CIImage?) -> CIImage {
        return autoreleasepool {
            let base = CIImage(cvPixelBuffer: pixelBuffer, options: [.colorSpace: colorSpace])
            
            // Early return for no overlay
            guard !preset.nodes.isEmpty else { return base }
            
            // Enrich tokens for personal preset
            var enrichedTokens = tokens
            if preset.id == "personal" || preset.id == "personal-custom" {
                // Read personal info from App Group storage (updated by main app)
                if let personalInfo = personalInfoReader.readPersonalInfo() {
                    enrichedTokens.city = enrichedTokens.city ?? personalInfo.city
                    enrichedTokens.localTime = enrichedTokens.localTime ?? personalInfo.localTime
                    enrichedTokens.weatherEmoji = enrichedTokens.weatherEmoji ?? personalInfo.weatherEmoji
                    enrichedTokens.weatherText = enrichedTokens.weatherText ?? personalInfo.weatherText
                    
                    // Debug log to see what values we're using
                    print("[CameraOverlayRenderer] Personal tokens - city: \(enrichedTokens.city ?? "nil"), time: \(enrichedTokens.localTime ?? "nil"), weather: \(enrichedTokens.weatherEmoji ?? "nil")")
                }
            }
            
            let width = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
            let height = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
            let containerSize = CGSize(width: width, height: height)
            
            // Create consolidated signature for cache key
            let signature = [
                enrichedTokens.displayName,
                enrichedTokens.tagline ?? "",
                enrichedTokens.accentColorHex,
                enrichedTokens.city ?? "",
                enrichedTokens.localTime ?? "",
                enrichedTokens.weatherEmoji ?? "",
                enrichedTokens.weatherText ?? ""
            ].joined(separator: "|")
            
            let key = LayoutKey(
                presetID: preset.id,
                aspect: enrichedTokens.aspect.rawValue,
                signature: signature
            )
            
            // Get overlay from cache or build it
            let overlay: CIImage = cacheQueue.sync {
                if let cached = cache.value(forKey: key) {
                    return cached
                } else {
                    let built = buildOverlayImage(preset: preset, tokens: enrichedTokens, size: containerSize)
                    cache.setValue(built, forKey: key)
                    return built
                }
            }

            // Crossfade handling between cached node-built images
            if lastKey != key || previousOverlay?.extent != overlay.extent {
                crossfadeStart = CACurrentMediaTime()
            }
            lastKey = key

            if let prev = previousOverlay,
               let start = crossfadeStart,
               CACurrentMediaTime() - start < crossfadeDuration,
               let dissolveFilter = CIFilter(name: "CIDissolveTransition")
            {
                let t = min((CACurrentMediaTime() - start) / crossfadeDuration, 1.0)
                dissolveFilter.setValue(prev, forKey: kCIInputImageKey)
                dissolveFilter.setValue(overlay, forKey: kCIInputTargetImageKey)
                dissolveFilter.setValue(t, forKey: kCIInputTimeKey)
                if let blended = dissolveFilter.outputImage {
                    let composited = blended.cropped(to: base.extent).composited(over: base)
                    if t >= 1.0 {
                        previousOverlay = overlay
                        crossfadeStart = nil
                    }
                    return composited
                }
            }

            previousOverlay = overlay
            return overlay.composited(over: base)
        }
    }
    
    /// Notify renderer that aspect ratio is changing
    func notifyAspectChanged() {
        crossfadeStart = CACurrentMediaTime()
    }
    
    // MARK: - Private Methods
    
    /// Build the overlay image by rendering all nodes to a Core Graphics context.
    ///
    /// This method is only called when the cache doesn't contain the requested overlay,
    /// avoiding expensive re-rendering of static content.
    ///
    /// - Parameters:
    ///   - preset: The preset defining the overlay structure
    ///   - tokens: Dynamic values to insert into the overlay
    ///   - size: Size of the video frame to render onto
    /// - Returns: A CIImage containing the rendered overlay with transparency
    private func buildOverlayImage(preset: OverlayPreset, tokens: OverlayTokens, size: CGSize) -> CIImage {
        let width = Int(size.width)
        let height = Int(size.height)
        
        // Create Core Graphics context with predictable configuration
        // Using premultiplied alpha for correct blending with video
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return CIImage.empty()
        }
        
        // Enable high-quality rendering
        context.interpolationQuality = .high
        context.setShouldAntialias(true)
        
        // Clear background
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        
        // Get placements and sort by z-index
        let placements = preset.layout.placements(for: tokens.aspect)
            .sorted { $0.zIndex < $1.zIndex }
        
        // Special handling for personal preset - don't render background if no data
        let hasPersonalData = (preset.id != "personal" && preset.id != "personal-custom") || 
            (tokens.city != nil && !tokens.city!.isEmpty) ||
            (tokens.weatherEmoji != nil && !tokens.weatherEmoji!.isEmpty)
        
        // Draw each node
        for placement in placements {
            guard placement.index < preset.nodes.count,
                  placement.opacity > 0 else { continue }
            
            let node = preset.nodes[placement.index]
            
            // Skip background rect for personal preset if no data
            if (preset.id == "personal" || preset.id == "personal-custom") && placement.index == 0 && !hasPersonalData {
                continue
            }
            
            // Apply pixel snapping for crisp edges
            let frame = placement.frame.toCGRect(in: size).integral
            
            context.saveGState()
            context.setAlpha(placement.opacity)
            
            switch node {
            case .rect(let rectNode):
                drawRect(rectNode, in: frame, tokens: tokens, context: context)
            case .gradient(let gradientNode):
                drawGradient(gradientNode, in: frame, tokens: tokens, context: context)
            case .text(let textNode):
                drawText(textNode, in: frame, tokens: tokens, context: context)
            }
            
            context.restoreGState()
        }
        
        // Convert to CIImage
        guard let cgImage = context.makeImage() else {
            return CIImage.empty()
        }
        
        return CIImage(cgImage: cgImage, options: [.colorSpace: colorSpace])
    }
    
    // MARK: - Core Graphics Drawing (No AppKit)
    
    /// Create a Core Text font using system font with specified weight.
    /// This avoids hardcoded font names and uses trait-based selection.
    private func createSystemFont(size: CGFloat, weightName: String) -> CTFont {
        let weight: CGFloat
        switch weightName.lowercased() {
        case "black":    weight = 0.62   // UIFontWeight.black equivalent
        case "heavy":    weight = 0.56   // UIFontWeight.heavy equivalent
        case "bold":     weight = 0.4    // UIFontWeight.bold equivalent
        case "semibold": weight = 0.3    // UIFontWeight.semibold equivalent
        case "medium":   weight = 0.23   // UIFontWeight.medium equivalent
        case "regular":  weight = 0.0    // UIFontWeight.regular equivalent
        case "light":    weight = -0.4   // UIFontWeight.light equivalent
        case "thin":     weight = -0.6   // UIFontWeight.thin equivalent
        case "ultralight": weight = -0.8 // UIFontWeight.ultraLight equivalent
        default:         weight = 0.0     // Default to regular
        }
        
        let traits: [CFString: Any] = [
            kCTFontWeightTrait: weight
        ]
        
        let attributes: [CFString: Any] = [
            kCTFontTraitsAttribute: traits
        ]
        
        let descriptor = CTFontDescriptorCreateWithAttributes(attributes as CFDictionary)
        return CTFontCreateWithFontDescriptor(descriptor, size, nil)
    }
    
    private func drawRect(_ node: RectNode, in frame: CGRect, tokens: OverlayTokens, context: CGContext) {
        guard let color = cgColor(from: node.colorHex.replacingTokens(with: tokens)) else { return }
        
        let radius = min(frame.width, frame.height) * node.cornerRadius
        let path = CGPath(roundedRect: frame, cornerWidth: radius, cornerHeight: radius, transform: nil)
        
        context.addPath(path)
        context.setFillColor(color)
        context.fillPath()
    }
    
    private func drawGradient(_ node: GradientNode, in frame: CGRect, tokens: OverlayTokens, context: CGContext) {
        guard let startColor = cgColor(from: node.startColorHex.replacingTokens(with: tokens)),
              let endColor = cgColor(from: node.endColorHex.replacingTokens(with: tokens)),
              let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: [startColor, endColor] as CFArray,
                locations: [0.0, 1.0]
              ) else { return }
        
        let angle = node.angle * .pi / 180.0
        let halfDiagonal = 0.5 * hypot(frame.width, frame.height)
        let center = CGPoint(x: frame.midX, y: frame.midY)
        
        let startPoint = CGPoint(
            x: center.x - cos(angle) * halfDiagonal,
            y: center.y - sin(angle) * halfDiagonal
        )
        let endPoint = CGPoint(
            x: center.x + cos(angle) * halfDiagonal,
            y: center.y + sin(angle) * halfDiagonal
        )
        
        context.saveGState()
        context.clip(to: frame)
        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        context.restoreGState()
    }
    
    private func drawText(_ node: TextNode, in frame: CGRect, tokens: OverlayTokens, context: CGContext) {
        // Special handling for personal preset - skip nodes with missing data
        if node.text.contains("{city}") && (tokens.city == nil || tokens.city?.isEmpty == true) {
            return // Skip city line if no city data
        }
        if node.text.contains("{weatherEmoji}") && (tokens.weatherEmoji == nil || tokens.weatherEmoji?.isEmpty == true) {
            return // Skip weather line if no weather data
        }
        
        let text = node.text.replacingTokens(with: tokens).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let fontSize = frame.height * 0.7
        let ctFont = createSystemFont(size: fontSize, weightName: node.fontWeight)
        let color = cgColor(from: node.colorHex.replacingTokens(with: tokens)) ?? CGColor(gray: 1.0, alpha: 1.0)
        
        var alignment: CTTextAlignment = .center
        switch node.alignment.lowercased() {
        case "left": alignment = .left
        case "right": alignment = .right
        default: alignment = .center
        }
        
        var alignmentSetting = CTParagraphStyleSetting(
            spec: .alignment,
            valueSize: MemoryLayout<CTTextAlignment>.size,
            value: withUnsafeBytes(of: alignment) { $0.baseAddress! }
        )
        let paragraphStyle = CTParagraphStyleCreate(&alignmentSetting, 1)
        
        let attrs: [CFString: Any] = [
            kCTFontAttributeName: ctFont,
            kCTForegroundColorAttributeName: color,
            kCTParagraphStyleAttributeName: paragraphStyle
        ]
        
        guard let attributed = CFAttributedStringCreate(kCFAllocatorDefault, text as CFString, attrs as CFDictionary) else { return }
        let framesetter = CTFramesetterCreateWithAttributedString(attributed)
        // Build text path in current CG space (no flips)
        let path = CGMutablePath()
        path.addRect(frame)

        context.saveGState()
        context.textMatrix = .identity

        let ctFrame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
        CTFrameDraw(ctFrame, context)

        context.restoreGState()
    }
    
    // MARK: - Helper Methods
    
    private func cgColor(from hex: String) -> CGColor? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexSanitized.hasPrefix("#") {
            hexSanitized.removeFirst()
        }
        
        guard let value = UInt64(hexSanitized, radix: 16),
              hexSanitized.count == 6 || hexSanitized.count == 8 else {
            return nil
        }
        
        let r, g, b, a: CGFloat
        
        if hexSanitized.count == 6 {
            r = CGFloat((value >> 16) & 0xFF) / 255.0
            g = CGFloat((value >> 8) & 0xFF) / 255.0
            b = CGFloat(value & 0xFF) / 255.0
            a = 1.0
        } else {
            r = CGFloat((value >> 24) & 0xFF) / 255.0
            g = CGFloat((value >> 16) & 0xFF) / 255.0
            b = CGFloat((value >> 8) & 0xFF) / 255.0
            a = CGFloat(value & 0xFF) / 255.0
        }
        
        return CGColor(colorSpace: colorSpace, components: [r, g, b, a])
    }
    
}

// MARK: - LRU Cache

/// Least Recently Used cache for storing rendered overlays.
///
/// This cache helps avoid re-rendering overlays that haven't changed,
/// significantly improving performance. The LRU eviction policy ensures
/// that the most frequently used overlays stay in memory while rarely
/// used ones are evicted when the cache reaches capacity.
///
/// Thread-safety note: This cache is not thread-safe. It should only be
/// accessed from a single thread or protected with external synchronization.
final class LRUCache<K: Hashable, V> {
    /// Maximum number of items to store in cache
    private let capacity: Int
    
    /// Dictionary for O(1) value lookup
    private var dict: [K: V] = [:]
    
    /// Array tracking access order (most recent at index 0)
    private var order: [K] = []
    
    init(capacity: Int) {
        self.capacity = max(1, capacity)
    }
    
    /// Retrieve a value from cache and update its position to most recently used
    func value(forKey key: K) -> V? {
        guard let value = dict[key] else { return nil }
        
        // Move accessed key to front (most recently used)
        if let index = order.firstIndex(of: key) {
            order.remove(at: index)
        }
        order.insert(key, at: 0)
        
        return value
    }
    
    func setValue(_ value: V, forKey key: K) {
        // Evict if at capacity
        if dict[key] == nil, dict.count >= capacity, let last = order.last {
            dict.removeValue(forKey: last)
            order.removeLast()
        }
        
        // Update value
        dict[key] = value
        
        // Move to front
        if let index = order.firstIndex(of: key) {
            order.remove(at: index)
        }
        order.insert(key, at: 0)
    }
    
    var count: Int { dict.count }
    
    func removeAll() {
        dict.removeAll()
        order.removeAll()
    }
}
