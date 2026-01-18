import SwiftUI

struct AnalysisCard: View {
    let analysis: APIService.AnalysisResult?
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Yapay Zeka Fiyat Analizi")
                .font(.headline)
            
            if isLoading {
                HStack {
                    ProgressView()
                    Text("Analiz ediliyor...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
            } else if let analysis = analysis {
                HStack(alignment: .top, spacing: 16) {
                    // Badge Icon
                    ZStack {
                        Circle()
                            .fill(badgeColor(for: analysis.recommendation).opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: badgeIcon(for: analysis.recommendation))
                            .font(.title2)
                            .foregroundColor(badgeColor(for: analysis.recommendation))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(analysis.recommendation == "BUY" ? "Şimdi Al" :
                             analysis.recommendation == "WAIT" ? "Bekle" : "Kaçırma")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(badgeColor(for: analysis.recommendation))
                        
                        Text(analysis.reason)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Confidence Bar
                        HStack {
                            Text("Güven Skoru: %\(Int(analysis.confidence * 100))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Capsule()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 50, height: 4)
                                .overlay(
                                    GeometryReader { geo in
                                        Capsule()
                                            .fill(badgeColor(for: analysis.recommendation))
                                            .frame(width: geo.size.width * analysis.confidence)
                                    }
                                )
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(badgeColor(for: analysis.recommendation).opacity(0.3), lineWidth: 1)
                )
            } else {
                Text("Analiz verisi alınamadı.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func badgeColor(for recommendation: String) -> Color {
        switch recommendation {
        case "BUY": return .green
        case "WAIT": return .orange
        case "DON'T BUY": return .red
        default: return .blue
        }
    }
    
    private func badgeIcon(for recommendation: String) -> String {
        switch recommendation {
        case "BUY": return "checkmark.seal.fill"
        case "WAIT": return "clock.fill"
        case "DON'T BUY": return "hand.raised.fill"
        default: return "brain.head.profile"
        }
    }
}
