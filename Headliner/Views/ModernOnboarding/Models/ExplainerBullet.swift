//
//  ExplainerBullet.swift
//  Headliner
//
//  Model for explainer card bullet points with icon and detail text
//

import Foundation

struct ExplainerBullet: Identifiable, Equatable {
    let id = UUID()
    let symbol: String
    let title: String
    let detail: String?
    
    init(symbol: String, title: String, detail: String? = nil) {
        self.symbol = symbol
        self.title = title
        self.detail = detail
    }
}