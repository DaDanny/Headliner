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

// MARK: - New Component-Based Presets

struct Professional_Previews: PreviewProvider {
    static var previews: some View {
        Professional()
            .makeView(tokens: .previewDanny)
            .previewLayout(.fixed(width: Professional.defaultSize.width,
                                  height: Professional.defaultSize.height))
            .background(Color.black)
            .previewDisplayName("Professional")
    }
}

struct ModernProfessional_Previews: PreviewProvider {
    static var previews: some View {
        ModernProfessional()
            .makeView(tokens: .previewDanny)
            .previewLayout(.fixed(width: ModernProfessional.defaultSize.width,
                                  height: ModernProfessional.defaultSize.height))
            .background(Color.black)
            .previewDisplayName("Modern Professional")
    }
}

struct CreatorMode_Previews: PreviewProvider {
    static var previews: some View {
        // Enhanced preview tokens with social media handles
        var creatorTokens = OverlayTokens.previewDanny
        creatorTokens.extras = [
            "location": "Pittsburgh, PA",
            "weatherEmoji": "☀️",
            "weatherText": "72°F",
            "twitter": "dannyfrancken",
            "instagram": "danny.codes",
            "youtube": "DevByDanny"
        ]
        
        return CreatorMode()
            .makeView(tokens: creatorTokens)
            .previewLayout(.fixed(width: CreatorMode.defaultSize.width,
                                  height: CreatorMode.defaultSize.height))
            .background(Color.black)
            .previewDisplayName("Creator Mode")
    }
}

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

struct BottomBarComponents_Previews: PreviewProvider {
    static var previews: some View {
        let accentColor = Color(hex: "#118342", default: .green)
        
        Group {
            VStack(spacing: 20) {
                BottomBar(
                    displayName: "Danny F",
                    tagline: "High School Intern",
                    accentColor: accentColor
                )
                
                BottomBarV2(
                    displayName: "Danny F",
                    tagline: "High School Intern",
                    accentColor: accentColor
                )
                
                BottomBarCompact(
                    displayName: "Danny F",
                    tagline: "High School Intern",
                    accentColor: accentColor
                )
                
                BottomBarGlass(
                    displayName: "Danny F",
                    tagline: "High School Intern",
                    accentColor: accentColor
                )
            }
            .padding()
            .background(Color.black)
            .previewDisplayName("Bottom Bar Components")
        }
    }
}

struct TickerComponents_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: 20) {
                WeatherTicker(
                    location: "Pittsburgh, PA",
                    weatherEmoji: "☀️",
                    temperature: "72°F"
                )
                
                TimeTicker(time: "8:04 PM")
                
                HStack(spacing: 12) {
                    MetricTicker(label: "Viewers", value: "1.2K", accentColor: .red)
                    MetricTicker(label: "Followers", value: "42.5K", accentColor: Color(hex: "#118342", default: .green))
                    MetricTicker(label: "Live", value: "ON AIR", accentColor: .orange)
                }
            }
            .padding()
            .background(Color.black)
            .previewDisplayName("Ticker Components")
        }
    }
}

struct BadgeComponents_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    LogoBadge(logoText: "BONUSLY", accentColor: Color(hex: "#118342", default: .green))
                    LogoBadge(logoText: "ACME CORP", accentColor: .blue)
                    LogoBadge(logoText: "TECH CO", accentColor: .purple)
                }
                
                HStack(spacing: 12) {
                    StatusBadge(status: .live)
                    StatusBadge(status: .recording)
                    StatusBadge(status: .offline)
                    StatusBadge(status: .custom("ON AIR", .purple))
                }
                
                HStack(spacing: 12) {
                    SocialBadge(platform: .twitter, handle: "dannyfrancken")
                    SocialBadge(platform: .instagram, handle: "danny.codes")
                    SocialBadge(platform: .youtube, handle: "DevByDanny")
                }
            }
            .padding()
            .background(Color.black)
            .previewDisplayName("Badge Components")
        }
    }
}

struct SafeAreaLive_Previews: PreviewProvider {
    static var previews: some View {
        SafeAreaLive()
            .makeView(tokens: OverlayTokens.previewDanny)
            .frame(width: 1920, height: 1080)
            .background(Color.black)
            .previewDisplayName("Safe Area Live")
    }
}
