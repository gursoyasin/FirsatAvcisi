import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var storeKit = StoreKitManager.shared
    @ObservedObject var subManager = SubscriptionManager.shared
    @State private var isPurchasing = false
    @State private var shine = false
    
    // Helper to get monthly product
    var monthlyProduct: StoreKit.Product? {
        storeKit.products.first
    }
    
    var body: some View {
        ZStack {
            // Dark Premium Background
            Color(hex: "0F172A").ignoresSafeArea()
            
            // Gradient Glows
            Circle().fill(Color.purple.opacity(0.3)).blur(radius: 100).offset(x: -100, y: -200)
            Circle().fill(Color.blue.opacity(0.2)).blur(radius: 100).offset(x: 100, y: 200)
            
            VStack(spacing: 24) {
                // Close Button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding()
                
                Spacer()
                
                // Icon / Hero
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                        .blur(radius: shine ? 20 : 0)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 2).repeatForever()) { shine.toggle() }
                }
                
                // Text
                VStack(spacing: 8) {
                    Text("Fırsat Avcısı PRO")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Limitlere Takılma, Fırsatları Kaçırma.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Features List
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "infinity", color: .blue, title: "Sınırsız Ürün Takibi", desc: "3 ürün limitini kaldır.")
                    FeatureRow(icon: "bolt.fill", color: .yellow, title: "Anlık Bildirimler", desc: "Fiyat düştüğü saniye haberin olsun.")
                    FeatureRow(icon: "target", color: .red, title: "Hedef Fiyat Alarmı", desc: "İstediğin fiyata düşünce uyar.")
                    FeatureRow(icon: "hand.raised.slash.fill", color: .green, title: "Reklamsız Deneyim", desc: "Sadece fırsatlara odaklan.")
                }
                .padding(.vertical, 20)
                
                Spacer()
                
                // REWARDED AD OPTION
                Button(action: {
                    AdManager.shared.showRewardedAd {
                        subManager.addFreeSlot()
                        dismiss()
                    }
                }) {
                    HStack {
                        Image(systemName: "play.square.fill")
                            .foregroundColor(.yellow)
                        Text("Reklam İzle (+1 Hak Kazan)")
                            .foregroundColor(.white)
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16).stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                    )
                }
                .padding(.bottom, 8)
                
                // Pricing Card
                Button(action: purchase) {
                    HStack {
                        if isPurchasing || storeKit.isLoading {
                            ProgressView()
                                .tint(.black)
                        } else {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Aylık Abonelik")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .opacity(0.8)
                                Text(monthlyProduct?.displayPrice ?? "79.99 TL / Ay")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            Text(monthlyProduct == nil ? "Yükleniyor..." : "Şimdi Başlat")
                                .fontWeight(.bold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(20)
                    .shadow(color: .white.opacity(0.2), radius: 20, x: 0, y: 10)
                }
                .disabled(isPurchasing || (monthlyProduct == nil && storeKit.products.isEmpty))
                
                // Footer
                HStack(spacing: 20) {
                    Button("Satın Alımları Geri Yükle") { subManager.restorePurchases() }
                    Text("•")
                    Button("Kullanım Koşulları") { }
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
                .padding(.bottom)
            }
            .padding()
        }
    }
    
    func purchase() {
        guard let product = monthlyProduct else { return }
        
        isPurchasing = true
        Task {
            do {
                try await storeKit.purchase(product)
                // If successful, storeKit updates SubscriptionManager.isPro automatically via listener
                if subManager.isPro {
                    dismiss()
                }
            } catch {
                print("Purchase failed: \(error)")
            }
            isPurchasing = false
        }
    }
}
import StoreKit

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
