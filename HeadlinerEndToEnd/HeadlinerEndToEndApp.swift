//
//  HeadlinerEndToEndApp.swift
//  HeadlinerEndToEnd
//
//  Created by Danny Francken on 8/2/25.
//

import SwiftUI

@main
struct HeadlinerEndToEndApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(endToEndStreamProvider: EndToEndStreamProvider())
        }
    }
}
