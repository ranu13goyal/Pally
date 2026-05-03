// iPal/Theme.swift
import SwiftUI

enum Theme {
    static let paperBackground = Color(red: 253/255, green: 251/255, blue: 247/255) // #FDFBF7
    static let inkText = Color(red: 44/255, green: 44/255, blue: 44/255) // #2C2C2C
    
    // Fallbacks for dark mode
    static let darkPaperBackground = Color(red: 28/255, green: 28/255, blue: 30/255)
    static let darkInkText = Color(red: 235/255, green: 235/255, blue: 235/255)
}

struct PaperBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content.background(colorScheme == .dark ? Theme.darkPaperBackground : Theme.paperBackground)
    }
}

struct InkTextModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content.foregroundColor(colorScheme == .dark ? Theme.darkInkText : Theme.inkText)
    }
}

extension View {
    func paperBackground() -> some View {
        modifier(PaperBackgroundModifier())
    }
    
    func inkText() -> some View {
        modifier(InkTextModifier())
    }
}
