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
