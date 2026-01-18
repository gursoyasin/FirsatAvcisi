import SwiftUI

struct SkeletonModifier: ViewModifier {
    var isLoading: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        if isLoading {
            content
                .overlay(
                    GeometryReader { geo in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1), Color.gray.opacity(0.3)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .mask(content)
                            .offset(x: -geo.size.width + (geo.size.width * 2 * phase))
                            .onAppear {
                                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                    phase = 1
                                }
                            }
                    }
                )
                .redacted(reason: .placeholder)
        } else {
            content
        }
    }
}

extension View {
    func skeleton(isLoading: Bool) -> some View {
        modifier(SkeletonModifier(isLoading: isLoading))
    }
}
