import SwiftUI

struct StandardLowerThird_Previews: PreviewProvider {
    static var previews: some View {
        StandardLowerThird()
            .makeView(tokens: .previewDanny)
            .previewLayout(.fixed(width: StandardLowerThird.defaultSize.width,
                                  height: StandardLowerThird.defaultSize.height))
            .background(Color.black) // preview contrast
            .previewDisplayName("Standard Lower Third")
    }
}

struct BrandRibbon_Previews: PreviewProvider {
    static var previews: some View {
        BrandRibbon()
            .makeView(tokens: .previewDanny)
            .previewLayout(.fixed(width: BrandRibbon.defaultSize.width,
                                  height: BrandRibbon.defaultSize.height))
            .background(Color.black)
            .previewDisplayName("Brand Ribbon")
    }
}

struct MetricChipBar_Previews: PreviewProvider {
    static var previews: some View {
        MetricChipBar()
            .makeView(tokens: .previewDanny)
            .previewLayout(.fixed(width: MetricChipBar.defaultSize.width,
                                  height: MetricChipBar.defaultSize.height))
            .background(Color.black)
            .previewDisplayName("Metric Chip Bar")
    }
}

struct NeoLowerThird_Previews: PreviewProvider {
    static var previews: some View {
        NeoLowerThird()
            .makeView(tokens: .previewDanny)
            .previewLayout(.fixed(width: NeoLowerThird.defaultSize.width,
                                  height: NeoLowerThird.defaultSize.height))
            .background(Color.black)
            .previewDisplayName("Neo Lower Third")
    }
}

struct CompanyCroppedLive_Previews: PreviewProvider {
    static var previews: some View {
        CompanyCropped()
            .makeView(tokens: .previewDanny)
            .previewLayout(.fixed(width: CompanyCropped.defaultSize.width,
                                  height: CompanyCropped.defaultSize.height))
            .background(Color.black)
            .previewDisplayName("Company Cropped")
    }
}

struct CompanyCroppedV2_Previews: PreviewProvider {
    static var previews: some View {
        CompanyCroppedV2()
            .makeView(tokens: .previewDanny)
            .previewLayout(.fixed(width: CompanyCroppedV2.defaultSize.width,
                                  height: CompanyCroppedV2.defaultSize.height))
            .background(Color.black)
            .previewDisplayName("Company Cropped V2")
    }
}

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
