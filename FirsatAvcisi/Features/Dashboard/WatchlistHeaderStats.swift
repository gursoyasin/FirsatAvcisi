import SwiftUI

struct WatchlistHeaderStats: View {
    let savedAmount: Double
    let totalValue: Double
    let trackingCount: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 1. Total Savings Card (Hero)
                WatchlistStatCard(
                    title: "Toplam Tasarruf",
                    value: savedAmount.formatted(.currency(code: "TRY")),
                    icon: "arrow.down.right.circle.fill",
                    color: .green,
                    subtext: "Yakalanan İndirimler"
                )
                
                // 2. Portfolio Value
                WatchlistStatCard(
                    title: "Takip Değeri",
                    value: totalValue.formatted(.currency(code: "TRY")),
                    icon: "briefcase.fill",
                    color: .blue,
                    subtext: "\(trackingCount) Ürün Takipte"
                )
                
                WatchlistStatCard(
                    title: "Hedeflenen",
                    value: "---", // Could calculate if targets set
                    icon: "target",
                    color: .orange,
                    subtext: "Beklenen Fiyatlar"
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

struct WatchlistStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtext: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .padding(8)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Spacer()
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.secondary.opacity(0.3))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(subtext)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(16)
        .frame(width: 160, height: 140)
        .background(Material.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
