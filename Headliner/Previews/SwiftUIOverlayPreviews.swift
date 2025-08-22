import SwiftUI

// StandardLowerThird_Previews - REMOVED (component deleted)
// BrandRibbon_Previews - REMOVED (component deleted)
// MetricChipBar_Previews - REMOVED (component deleted)
// NeoLowerThird_Previews - REMOVED (component deleted)
// CompanyCroppedLive_Previews - REMOVED (component deleted)
// CompanyCroppedV2_Previews - REMOVED (component deleted)

struct AspectRatioTest_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 1) Native design space (exactly what the overlay declares)
            AspectRatioTest()
                .makeView(tokens: .previewDanny)
                .overlay(RoundedRectangle(cornerRadius: 0).stroke(.red.opacity(0.6), lineWidth: 1))
                .background(Color.black)
                .previewLayout(.fixed(width: AspectRatioTest.defaultSize.width,
                                      height: AspectRatioTest.defaultSize.height))
                .previewDisplayName("Native \(Int(AspectRatioTest.defaultSize.width))×\(Int(AspectRatioTest.defaultSize.height))")

            // 2) 16:9 canvas (simulate your 1920×1080 output; quarter scale to keep previews light)
            AspectRatioTest()
                .makeView(tokens: .previewDanny)
                .overlay(RoundedRectangle(cornerRadius: 0).stroke(.yellow.opacity(0.6), lineWidth: 1))
                .background(Color.black)
                .previewLayout(.fixed(width: 1920/4, height: 1080/4))
                .previewDisplayName("16:9 Canvas (1920×1080 @¼)")

            // 3) 4:3 canvas (should show centered GREEN safe box with pillar bars)
            AspectRatioTest()
                .makeView(tokens: .previewDanny)
                .overlay(RoundedRectangle(cornerRadius: 0).stroke(.green.opacity(0.6), lineWidth: 1))
                .background(Color.black)
                .previewLayout(.fixed(width: 800, height: 600))
                .previewDisplayName("4:3 Canvas (800×600)")

            // 4) Square stress test (helps reveal accidental aspect-forcing)
            AspectRatioTest()
                .makeView(tokens: .previewDanny)
                .overlay(RoundedRectangle(cornerRadius: 0).stroke(.blue.opacity(0.6), lineWidth: 1))
                .background(Color.black)
                .previewLayout(.fixed(width: 700, height: 700))
                .previewDisplayName("Square Stress (700×700)")
        }
    }
}

struct AspectRatioTestV2_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 1) Native design space (exactly what the overlay declares)
            AspectRatioTestV2()
                .makeView(tokens: .previewDanny)
                .overlay(RoundedRectangle(cornerRadius: 0).stroke(.red.opacity(0.6), lineWidth: 1))
                .background(Color.black)
                .previewLayout(.fixed(width: AspectRatioTestV2.defaultSize.width,
                                      height: AspectRatioTestV2.defaultSize.height))
                .previewDisplayName("V2 Native \(Int(AspectRatioTestV2.defaultSize.width))×\(Int(AspectRatioTestV2.defaultSize.height))")

            // 2) 16:9 canvas (simulate your 1920×1080 output; quarter scale to keep previews light)
            AspectRatioTestV2()
                .makeView(tokens: .previewDanny)
                .overlay(RoundedRectangle(cornerRadius: 0).stroke(.yellow.opacity(0.6), lineWidth: 1))
                .background(Color.black)
                .previewLayout(.fixed(width: 1920/4, height: 1080/4))
                .previewDisplayName("V2 16:9 Canvas (1920×1080 @¼)")

            // 3) 4:3 canvas (should show centered GREEN safe box with pillar bars)
            AspectRatioTestV2()
                .makeView(tokens: .previewDanny)
                .overlay(RoundedRectangle(cornerRadius: 0).stroke(.green.opacity(0.6), lineWidth: 1))
                .background(Color.black)
                .previewLayout(.fixed(width: 800, height: 600))
                .previewDisplayName("V2 4:3 Canvas (800×600)")

            // 4) Square stress test (helps reveal accidental aspect-forcing)
            AspectRatioTestV2()
                .makeView(tokens: .previewDanny)
                .overlay(RoundedRectangle(cornerRadius: 0).stroke(.blue.opacity(0.6), lineWidth: 1))
                .background(Color.black)
                .previewLayout(.fixed(width: 700, height: 700))
                .previewDisplayName("V2 Square Stress (700×700)")
        }
    }
}

// MARK: - Component-Based Presets

// Professional_Previews - REMOVED (component deleted)
// ModernProfessional_Previews - REMOVED (component deleted)

struct ModernPersonal_Previews: PreviewProvider {
    static var previews: some View {
        ModernPersonal()
            .makeView(tokens: .previewDanny)
            .previewLayout(.fixed(width: ModernPersonal.defaultSize.width,
                                  height: ModernPersonal.defaultSize.height))
            .background(Color.black)
            .previewDisplayName("Modern Personal")
    }
}

// CreatorMode_Previews - REMOVED (component deleted)

struct SafeAreaValidation_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Full size validation view
            SafeAreaValidation()
                .makeView(tokens: .previewDanny)
                .previewLayout(.fixed(width: SafeAreaValidation.defaultSize.width,
                                      height: SafeAreaValidation.defaultSize.height))
                .background(Color.black)
                .previewDisplayName("Safe Area Validation (1920×1080)")
            
            // Quarter scale for easier viewing
            SafeAreaValidation()
                .makeView(tokens: .previewDanny)
                .previewLayout(.fixed(width: 1920/4, height: 1080/4))
                .background(Color.black)
                .previewDisplayName("Safe Area Validation (@¼)")
            
            // 4:3 aspect test
            SafeAreaValidation()
                .makeView(tokens: .previewDanny)
                .previewLayout(.fixed(width: 800, height: 600))
                .background(Color.black)
                .previewDisplayName("Safe Area Validation (4:3)")
        }
    }
}

struct SafeAreaTest_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Direct comparison with AspectRatioTestV2
            SafeAreaTest()
                .makeView(tokens: .previewDanny)
                .previewLayout(.fixed(width: SafeAreaTest.defaultSize.width,
                                      height: SafeAreaTest.defaultSize.height))
                .background(Color.black)
                .previewDisplayName("Safe Area Test (Should Match AspectRatioTestV2 Yellow)")
            
            // Quarter scale for easier viewing
            SafeAreaTest()
                .makeView(tokens: .previewDanny)
                .previewLayout(.fixed(width: 1920/4, height: 1080/4))
                .background(Color.black)
                .previewDisplayName("Safe Area Test (@¼)")
        }
    }
}

// MARK: - Component Library Previews

// BottomBarComponents_Previews - REMOVED (most components deleted)

// TickerComponents_Previews - REMOVED (all components deleted)

// BadgeComponents_Previews - REMOVED (all components deleted)

struct SafeAreaLive_Previews: PreviewProvider {
    static var previews: some View {
        SafeAreaLive()
            .makeView(tokens: OverlayTokens.previewDanny)
            .frame(width: 1920, height: 1080)
            .background(Color.black)
            .previewDisplayName("Safe Area Live")
    }
}
