import SwiftUI

public enum SurfaceStyle: String, CaseIterable, Identifiable {
    case rounded
    case square
    
    public var id: String { rawValue }
}
