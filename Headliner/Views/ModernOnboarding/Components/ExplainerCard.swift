//
//  ExplainerCard.swift
//  Headliner
//
//  Richer left-panel content for modern onboarding with bullets and metadata
//

import SwiftUI

struct ExplainerCard: View {
    let title: String
    let subtitle: String
    let bullets: [ExplainerBullet]
    let timeEstimate: String
    let learnMoreAction: (() -> Void)?
    
    init(
        title: String,
        subtitle: String,
        bullets: [ExplainerBullet],
        timeEstimate: String,
        learnMoreAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.bullets = bullets
        self.timeEstimate = timeEstimate
        self.learnMoreAction = learnMoreAction
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title + subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .tracking(-0.2)
                
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Checklist bullets
            VStack(alignment: .leading, spacing: 8) {
                ForEach(bullets) { bullet in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: bullet.symbol)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.tint)
                            .frame(width: 16, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bullet.title)
                                .font(.callout.weight(.semibold))
                            if let detail = bullet.detail {
                                Text(detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(.top, 2)
            
            Spacer(minLength: 0)
            
            // Meta row: time + learn more
            HStack(spacing: 10) {
                Label(timeEstimate, systemImage: "clock")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary.opacity(0.25))
                    .clipShape(Capsule())
                
                if let learnMoreAction {
                    Button("Learn more", action: learnMoreAction)
                        .buttonStyle(.link)
                        .font(.caption)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .frame(minWidth: 300, idealWidth: 300, maxWidth: 300, alignment: .topLeading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#if DEBUG
struct ExplainerCard_Previews: PreviewProvider {
    static var previews: some View {
        ExplainerCard(
            title: "Let's Get Started",
            subtitle: "A quick setup to get your virtual camera looking sharp.",
            bullets: [
                .init(symbol: "sparkles", title: "What Headliner does", detail: "Clean overlays that look great in Meet and Zoom."),
                .init(symbol: "hand.tap", title: "Simple steps", detail: "Install, personalize, preview — then you're ready."),
                .init(symbol: "lock.shield", title: "Private by design", detail: "Runs locally; you control what's shown.")
            ],
            timeEstimate: "~1 min"
        )
        .padding()
        .background(.regularMaterial)
        .frame(width: 500, height: 600)
    }
}
#endif
