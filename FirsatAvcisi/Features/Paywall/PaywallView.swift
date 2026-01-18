import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Arkaplan Gradient
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                Spacer()
                
                // İkon ve Başlık
                Image(systemName: "crown.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.5), radius: 20, x: 0, y: 0)
                
                Text("Fırsat Avcısı PRO")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Sınırları Kaldır, Gerçek İndirimleri Yakala!")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Özellikler Listesi
                VStack(alignment: .leading, spacing: 15) {
                    FeatureRow(icon: "infinity", text: "Sınırsız Ürün Takibi")
                    FeatureRow(icon: "bell.badge.fill", text: "Anlık Fiyat Bildirimleri")
                    FeatureRow(icon: "chart.xyaxis.line", text: "90 Günlük Fiyat Geçmişi")
                    FeatureRow(icon: "bolt.fill", text: "Daha Hızlı Takip (30dk)")
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
                
                // Satın Alma Butonu
                Button(action: {
                    // StoreKit entegrasyonu (Mock)
                    dismiss()
                }) {
                    VStack {
                        Text("Pro'ya Geç - ₺199,90 / Yıl")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("7 Gün Ücretsiz Deneme")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                }
                .padding(.horizontal)
                
                Button("Geri Dön") {
                    dismiss()
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.bottom)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.yellow)
                .frame(width: 25)
            Text(text)
                .foregroundColor(.white)
                .font(.subheadline)
            Spacer()
        }
    }
}

#Preview {
    PaywallView()
}
