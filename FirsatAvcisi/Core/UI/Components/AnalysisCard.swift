import SwiftUI

struct AnalysisCard: View {
    let analysis: APIService.AnalysisResult?
    let isLoading: Bool
    
    // Animation States
    @State private var isAppearing = false
    @State private var pulse = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .symbolEffect(.bounce, value: isLoading) // iOS 17+
                
                Text(isLoading ? "Yapay Zeka Çalışıyor..." : "Analiz Raporu")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(.bottom, 12)
            
            if isLoading {
                ScanningView()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if let analysis = analysis {
                ResultView(analysis: analysis)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity).animation(.spring(response: 0.5, dampingFraction: 0.7)),
                        removal: .opacity
                    ))
            } else {
                AnalysisEmptyStateView()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal)
        .animation(.default, value: isLoading)
    }
}

// MARK: - Subviews

struct ScanningView: View {
    @State private var rotation = 0.0
    @State private var circles: [CGFloat] = [0.5, 0.9]
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Radar Circles
                ForEach(0..<2) { i in
                    Circle()
                        .stroke(
                            AngularGradient(gradient: Gradient(colors: [.blue.opacity(0), .blue.opacity(0.5), .purple.opacity(0.5), .blue.opacity(0)]), center: .center),
                            lineWidth: 2
                        )
                        .rotationEffect(.degrees(rotation))
                        .animation(
                            Animation.linear(duration: 2).repeatForever(autoreverses: false).delay(Double(i) * 0.5),
                            value: rotation
                        )
                }
                .frame(width: 80, height: 80)
                
                // Pulsing Brain
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 30))
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .scaleEffect(circles[0])
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: circles[0])
            }
            .onAppear {
                rotation = 360
                circles[0] = 1.1
            }
            
            VStack(spacing: 6) {
                Text("Ürün Verileri İnceleniyor")
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.medium)
                
                Text("Fiyat geçmişi, yorumlar ve stok durumu taranıyor...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }
}

struct ResultView: View {
    let analysis: APIService.AnalysisResult
    @State private var progress: CGFloat = 0
    @State private var glow = false
    
    var theme: (color: Color, gradient: [Color], icon: String) {
        switch analysis.recommendation {
        case "BUY":
            return (.green, [.green, .mint], "checkmark.seal.fill")
        case "WAIT":
            return (.orange, [.orange, .yellow], "clock.fill")
        case "NEW":
            return (.blue, [.blue, .cyan], "info.circle.fill")
        case "DON'T BUY":
            return (.red, [.red, .pink], "hand.raised.fill")
        default:
            return (.blue, [.blue, .cyan], "brain.fill")
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Animated Icon Badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: theme.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .opacity(0.15)
                        .frame(width: 60, height: 60)
                        
                    Circle()
                        .stroke(theme.color.opacity(0.3), lineWidth: 1)
                        .frame(width: 60, height: 60)
                        .scaleEffect(glow ? 1.1 : 1.0)
                        .opacity(glow ? 0 : 1)
                        .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: glow)

                    Image(systemName: theme.icon)
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(colors: theme.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizedRecommendation)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.color)
                    
                    Text("Güven Skoru: %\(Int(analysis.confidence * 100))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(theme.color.opacity(0.1))
                        )
                }
                Spacer()
            }
            
            // Description
            Text(analysis.reason)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.8))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .systemBackground).opacity(0.5))
                )
            
            // Animated Confidence Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("AI Kesinlik Oranı")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(
                                LinearGradient(colors: theme.gradient, startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: geo.size.width * progress, height: 8)
                            .shadow(color: theme.color.opacity(0.5), radius: 4, x: 0, y: 0)
                    }
                }
                .frame(height: 8)
            }
        }
        .onAppear {
            glow = true
            withAnimation(.spring(response: 1, dampingFraction: 0.7).delay(0.2)) {
                progress = analysis.confidence
            }
        }
    }
    
    var localizedRecommendation: String {
        switch analysis.recommendation {
        case "BUY": return "Fırsat! Hemen Al"
        case "WAIT": return "Biraz Bekle"
        case "NEW": return "Takip Başladı"
        case "DON'T BUY": return "Şimdilik Alma"
        default: return "İnceleniyor"
        }
    }
}

struct AnalysisEmptyStateView: View {
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
            Text("Analiz verisi oluşturulamadı.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}
