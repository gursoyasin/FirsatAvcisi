import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil
    
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                    .offset(y: animate ? -5 : 5)
                    .animation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animate)
            }
            .onAppear { animate = true }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if let buttonTitle = buttonTitle, let action = action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(25)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    EmptyStateView(
        icon: "bag.badge.plus",
        title: "Liste Henüz Boş",
        message: "Takip etmek istediğin ürünlerin linkini buraya yapıştır veya paylaşım eklentisini kullan.",
        buttonTitle: "İlk Ürünü Ekle",
        action: {}
    )
}
