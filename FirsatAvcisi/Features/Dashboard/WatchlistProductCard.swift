import SwiftUI
import Charts

struct WatchlistProductCard: View {
    let product: Product
    let onRemove: () -> Void
    let onSetAlert: () -> Void
    
    // Smooth Animation for Chart
    @State private var animateChart = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. Top Section: Image & Basic Info
            HStack(alignment: .top, spacing: 12) {
                // Product Image
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.1))
                }
                .frame(width: 80, height: 80)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    // Badge Row
                    if let diff = calculateDropPercentage(), diff > 1 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                            Text("%\(Int(diff)) İndirim")
                                .font(.caption2.bold())
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    } else if !(product.inStock ?? true) {
                        Text("Stokta Yok")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.secondary)
                            .clipShape(Capsule())
                    }
                    
                    Text(product.title)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true) // Text height fixes
                    
                    // Price Area (Moved up slightly)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(product.currentPrice.formatted(.currency(code: "TRY")))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(getPriceColor())
                        
                        if let old = getHighestPrice(), old > product.currentPrice {
                            Text(old.formatted(.currency(code: "TRY")))
                                .font(.caption2)
                                .strikethrough()
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 2)
                }
                
                Spacer(minLength: 0)
                
                // Action Menu
                Menu {
                    Button(role: .destructive, action: onRemove) {
                        Label("Takibi Bırak", systemImage: "trash")
                    }
                    Button(action: onSetAlert) {
                        Label("Alarm Kur", systemImage: "bell.badge")
                    }
                    if let url = URL(string: product.url) {
                        Link(destination: url) {
                            Label("Ürüne Git", systemImage: "safari")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(12)
            
            // 2. Bottom Section: Mini Chart or Status
            if let history = product.history, history.count > 1 {
                Divider().opacity(0.5)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Son 7 Gün")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        // Mini trend indicator could go here
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    
                    Chart {
                        ForEach(Array(history.prefix(10).reversed().enumerated()), id: \.offset) { index, item in
                            LineMark(
                                x: .value("Day", index),
                                y: .value("Price", item.price)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(getPriceColor())
                            .lineStyle(StrokeStyle(lineWidth: 1.5))
                            
                            AreaMark(
                                x: .value("Day", index),
                                y: .value("Price", item.price)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [getPriceColor().opacity(0.1), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                    }
                    .chartYAxis(.hidden)
                    .chartXAxis(.hidden)
                    .frame(height: 30) // More compact height
                    .padding(.horizontal, 4)
                    .padding(.bottom, 8)
                }
                .background(Color.gray.opacity(0.02))
            } else {
                // Empty state for bottom part to keep visual consistency if desired, or just nothing (compact)
                // For "compact" and clean look, we do nothing here, letting card end naturally.
            }
        }
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
    }
    
    // Helpers
    private func getHighestPrice() -> Double? {
        return product.history?.map { $0.price }.max()
    }
    
    private func calculateDropPercentage() -> Double? {
        guard let old = getHighestPrice(), old > 0 else { return nil }
        return ((old - product.currentPrice) / old) * 100
    }
    
    private func getPriceColor() -> Color {
        if let old = getHighestPrice(), product.currentPrice < old {
            return .green // Discount
        } else if !(product.inStock ?? true) {
            return .secondary
        }
        return .primary
    }
}
