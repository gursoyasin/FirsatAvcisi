import SwiftUI
import Combine

struct SmartAddSheet: View {
    @StateObject private var viewModel = AddProductViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var clipboardLink: String?
    @State private var showScanner = false
    @State private var showPaywall = false // Paywall State
    
    // Check Limit
    func checkLimitAndProceed(action: @escaping () -> Void) {
        if SubscriptionManager.shared.canAddProduct {
            action()
        } else {
            showPaywall = true
        }
    }
    
    let magicGradient = LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
    
    var body: some View {
        ZStack {
            // Background Layer
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            // Decorative Blobs for "Magic" feel
            GeometryReader { geo in
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: -50, y: -50)
                
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .blur(radius: 50)
                    .offset(x: geo.size.width - 150, y: geo.size.height - 150)
            }
            
            VStack(spacing: 24) {
                // Handle indicator
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                
                if viewModel.isLoading {
                    MagicLoadingView()
                } else if let preview = viewModel.previewProduct {
                    SuccessResultView(preview: preview, viewModel: viewModel)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                } else {
                    // Main Input Section
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Büyülü Ekleme")
                                .font(.system(size: 24, weight: .black, design: .serif))
                            Text("Linkini bırak, piyasayı biz izleyelim.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // 1. CLIPBOARD DETECTION (Redesigned)
                        if let link = clipboardLink {
                            ClipboardDetectionCard(link: link) {
                                checkLimitAndProceed {
                                    viewModel.url = link
                                    Task { await viewModel.analyzeLink() }
                                }
                            } onCancel: {
                                withAnimation { clipboardLink = nil }
                            }
                        }
                        
                        // 2. MANUAL INPUT
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                TextField("Ürün linkini buraya yapıştır...", text: $viewModel.url)
                                    .font(.system(.body, design: .rounded))
                                    .disableAutocorrection(true)
                                    .autocapitalization(.none)
                            }
                            .padding(18)
                            .background(Color(.secondarySystemBackground).opacity(0.8))
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                            )
                            
                            HStack(spacing: 14) {
                                CustomSmallButton(title: "Yapıştır", icon: "doc.on.clipboard", color: .gray) {
                                    if let string = UIPasteboard.general.string {
                                        viewModel.url = string
                                        HapticManager.shared.impact(style: .light)
                                    }
                                }
                                
                                CustomSmallButton(title: "Barkod", icon: "barcode.viewfinder", color: .gray) {
                                    showScanner = true
                                }
                            }
                        }
                        
                        // Action Button
                        Button(action: {
                            checkLimitAndProceed {
                                Task { await viewModel.analyzeLink() }
                            }
                        }) {
                            Text("Analiz Et")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(viewModel.url.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                                .cornerRadius(20)
                                .shadow(color: .blue.opacity(viewModel.url.isEmpty ? 0 : 0.2), radius: 10, x: 0, y: 5)
                        }
                        .disabled(viewModel.url.isEmpty)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
        }
        .onAppear { 
            checkClipboard()
            SubscriptionManager.shared.refreshStats()
        }
        .sheet(isPresented: $showScanner) { BarcodeScannerView() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onChange(of: viewModel.shouldDismiss) { _, newValue in
             if newValue { dismiss() }
        }
    }
    
    private func checkClipboard() {
        if let string = UIPasteboard.general.string, string.lowercased().contains("http") {
            clipboardLink = string
        }
    }
}

// MARK: - Premium Sub-components

struct MagicLoadingView: View {
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0.5
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                // Pulsing Rings
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .scaleEffect(ringScale + CGFloat(i) * 0.2)
                        .opacity(ringOpacity - Double(i) * 0.15)
                }
                
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .symbolEffect(.bounce, options: .repeating)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    ringScale = 1.1
                    ringOpacity = 0.8
                }
            }
            
            VStack(spacing: 8) {
                Text("Büyü Başlıyor...")
                    .font(.system(.headline, design: .serif))
                Text("Ürün detayları taranıyor, saniyeler içindeyiz.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
    }
}

struct ClipboardDetectionCard: View {
    let link: String
    let onAccept: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color(uiColor: .systemBackground)).frame(width: 40, height: 40)
                    Image(systemName: "sparkles").foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bunu mu yakaladın?")
                        .font(.system(size: 16, weight: .bold))
                    Text("Panonda bir link bulduk.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            HStack {
                Image(systemName: "link").font(.caption).foregroundColor(.blue)
                Text(link).font(.system(size: 12)).lineLimit(1).foregroundColor(.blue)
                Spacer()
            }
            .padding(12)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
            
            HStack(spacing: 12) {
                Button(action: onAccept) {
                    Text("Analizi Başlat")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct SuccessResultView: View {
    let preview: AddProductViewModel.ProductPreview
    let viewModel: AddProductViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            // Mirror Card
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: preview.imageUrl)) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.1))
                    }
                    .frame(height: 220)
                    .clipped()
                    
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Onaylandı ✅")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                        
                        // DELICI FEATURE: Miss Shield Badge
                        HStack(spacing: 4) {
                            Image(systemName: "shield.check.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                            Text("Stok Koruması")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    }
                    .padding(16)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(preview.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .lineLimit(2)
                    
                    HStack {
                        Text("\(Int(preview.currentPrice))₺")
                            .font(.title3)
                            .fontWeight(.black)
                        
                        Spacer()
                        
                        Text(preview.source.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                .padding(24)
            }
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 24)
            
            // DELICI FEATURE: Target Price & Probability
            if preview.currentPrice > 0 {
                VStack(spacing: 12) {
                    HStack {
                        Text("Hedef Fiyatım")
                            .font(.headline)
                        Spacer()
                        if let target = viewModel.targetPrice {
                            let prob = viewModel.getProbability(current: preview.currentPrice, target: target)
                            HStack(spacing: 4) {
                                Circle().fill(prob.color).frame(width: 8, height: 8)
                                Text(prob.text)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(prob.color)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(prob.color.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 28)
                    
                    HStack {
                        Text(viewModel.targetPrice == nil ? "Mevcut Fiyat (\(Int(preview.currentPrice))₺)" : "\(Int(viewModel.targetPrice!))₺")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                            .frame(width: 100, alignment: .leading)
                        
                        Slider(
                            value: Binding(
                                get: { viewModel.targetPrice ?? preview.currentPrice },
                                set: { viewModel.targetPrice = $0 }
                            ),
                            in: (preview.currentPrice * 0.5)...preview.currentPrice,
                            step: 10
                        )
                    }
                    .padding(.horizontal, 28)
                    
                    if let target = viewModel.targetPrice, target < preview.currentPrice {
                        let discount = Int((preview.currentPrice - target) / preview.currentPrice * 100)
                        Text("%\(discount) indirim bekliyorsunuz")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("Fiyat bilgisi alınamadı. Lütfen kaydedip düzenleyin.")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    AdManager.shared.showInterstitial()
                    HapticManager.shared.notification(type: .success)
                    Task { await viewModel.saveProduct() }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Listeme Ekle")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(Color.green)
                    .cornerRadius(20)
                    .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                
                Button("Yanlış Ürün? Tekrar Dene") {
                    withAnimation { viewModel.previewProduct = nil }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .onAppear {
            HapticManager.shared.notification(type: .success)
        }
    }
}

struct CustomSmallButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).font(.system(size: 14))
                Text(title).font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .foregroundColor(.primary)
            .cornerRadius(12)
        }
    }
}

// Helper for Alert
struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}
