import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    HapticManager.shared.impact(style: .light)
                }
            }
    }
}
