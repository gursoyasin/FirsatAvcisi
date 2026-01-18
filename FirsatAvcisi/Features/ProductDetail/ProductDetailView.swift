import SwiftUI
import Charts

struct ProductDetailView: View {
    @StateObject var viewModel: ProductDetailViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showCollectionSheet = false
    
    // Sharing
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    
    // Chart Interaction
    @State private var selectedDate: Date?
    @State private var selectedPrice: Double?
    
    init(product: Product) {
        _viewModel = StateObject(wrappedValue: ProductDetailViewModel(product: product))
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Parallax Image Header
                    GeometryReader { geometry in
                        let minY = geometry.frame(in: .global).minY
                        
                        AsyncImage(url: URL(string: viewModel.product.imageUrl ?? "")) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height + (minY > 0 ? minY : 0))
                                .offset(y: minY > 0 ? -minY : 0)
                                .clipped()
                        } placeholder: {
                            Color.gray.opacity(0.1)
                        }
                    }
                    .frame(height: 350)
                    
                    // Content Body
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Title & Price Section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(viewModel.product.source.uppercased())
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.black.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                
                                Spacer()
                                
                                // Fırsat Skoru
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text("\(viewModel.opportunityScore)/100")
                                        .fontWeight(.bold)
                                }
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(scoreColor(viewModel.opportunityScore))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            
                            Text(viewModel.product.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .lineLimit(3)
                                .foregroundColor(.primary)
                            
                            HStack(alignment: .firstTextBaseline) {
                                Text("\(viewModel.product.currentPrice, format: .currency(code: "TRY"))")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(.blue)
                                
                                if let inStock = viewModel.product.inStock, !inStock {
                                    Text("STOKTA YOK")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.red)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                        .offset(y: -30) // Overlap effect
                        .padding(.bottom, -30)
                        
                            // AI Analysis Card (Ultra Feature)
                            AnalysisCard(analysis: viewModel.analysisResult, isLoading: viewModel.isAnalyzeLoading)
                                .padding(.horizontal)
                            
                            // Statistics Cards
                            HStack(spacing: 12) {
                            StatCard(title: "En Düşük", value: viewModel.minPrice, icon: "arrow.down.circle.fill", color: .green)
                            StatCard(title: "Ortalama", value: viewModel.averagePrice, icon: "equal.circle.fill", color: .blue)
                            StatCard(title: "En Yüksek", value: viewModel.maxPrice, icon: "arrow.up.circle.fill", color: .red)
                        }
                        .padding(.horizontal)
                        
                        // Interactive Chart Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Fiyat Analizi")
                                    .font(.headline)
                                Spacer()
                                if let p = selectedPrice {
                                    Text(p, format: .currency(code: "TRY"))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                        .transition(.scale)
                                }
                            }
                            
                            Chart {
                                ForEach(viewModel.priceHistory) { point in
                                    AreaMark(
                                        x: .value("Tarih", point.date),
                                        y: .value("Fiyat", point.price)
                                    )
                                    .foregroundStyle(LinearGradient(colors: [.blue.opacity(0.3), .blue.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                                    .interpolationMethod(.catmullRom)
                                    
                                    LineMark(
                                        x: .value("Tarih", point.date),
                                        y: .value("Fiyat", point.price)
                                    )
                                    .foregroundStyle(Color.blue)
                                    .interpolationMethod(.catmullRom)
                                }
                                
                                if let selDate = selectedDate {
                                    RuleMark(x: .value("Seçili", selDate))
                                        .foregroundStyle(Color.gray.opacity(0.5))
                                }
                            }
                            .chartOverlay { proxy in
                                GeometryReader { geometry in
                                    Rectangle().fill(.clear).contentShape(Rectangle())
                                        .gesture(
                                            DragGesture()
                                                .onChanged { value in
                                                    let x = value.location.x
                                                    if let date: Date = proxy.value(atX: x) {
                                                        selectedDate = date
                                                        // Find closest price
                                                        if let closest = viewModel.priceHistory.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                                                            selectedPrice = closest.price
                                                            // Haptic Feedback
                                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                                            generator.impactOccurred()
                                                        }
                                                    }
                                                }
                                                .onEnded { _ in
                                                    selectedDate = nil
                                                    selectedPrice = nil
                                                }
                                        )
                                }
                            }
                            .frame(height: 220)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.03), radius: 5)
                        .padding(.horizontal)
                        
                        // Target Price Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fiyat Alarmı")
                                .font(.headline)
                            
                            HStack {
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(.orange)
                                    .font(.title2)
                                
                                VStack(alignment: .leading) {
                                    Text("Hedef Fiyat")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("0,00 ₺", value: Binding(
                                        get: { viewModel.product.targetPrice ?? 0 },
                                        set: { newValue in
                                            Task { await viewModel.updateTargetPrice(newValue) }
                                        }
                                    ), format: .currency(code: "TRY"))
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 18, weight: .bold))
                                }
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { (viewModel.product.targetPrice ?? 0) > 0 },
                                    set: { _ in } // Toggle is visual only for now
                                ))
                                .labelsHidden()
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.03), radius: 5)
                        }
                        .padding(.horizontal)
                        
                        // Cross-Market Alternatives (Cimri/Akakçe Mode)
                        if !viewModel.alternatives.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Diğer Satıcılar (Fiyat Karşılaştırma)")
                                    .font(.headline)
                                
                                VStack(spacing: 0) {
                                    ForEach(viewModel.alternatives) { alt in
                                        Link(destination: URL(string: alt.url)!) {
                                            HStack {
                                                Image(systemName: "cart.fill")
                                                    .foregroundColor(.blue)
                                                    .frame(width: 30)
                                                
                                                VStack(alignment: .leading) {
                                                    Text(alt.market.uppercased())
                                                        .font(.caption2)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.gray)
                                                    Text(alt.title)
                                                        .font(.subheadline)
                                                        .lineLimit(1)
                                                        .foregroundColor(.primary)
                                                }
                                                
                                                Spacer()
                                                
                                                Text(alt.price, format: .currency(code: "TRY"))
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(alt.price < viewModel.product.currentPrice ? .green : .primary)
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.horizontal)
                                            .contentShape(Rectangle())
                                        }
                                        
                                        if alt.id != viewModel.alternatives.last?.id {
                                            Divider().padding(.leading, 46)
                                        }
                                    }
                                }
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.03), radius: 5)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 120) // Extra space for floating bar
                    }
                }
            }
            .edgesIgnoringSafeArea(.top)
            
            // Custom Back Button & Actions
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "arrow.left")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Button { showCollectionSheet = true } label: {
                        Image(systemName: "folder.badge.plus")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.blue.opacity(0.8))
                            .clipShape(Circle())
                    }
                    Button { showDeleteConfirmation = true } label: {
                        Image(systemName: "trash.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.red.opacity(0.8))
                            .clipShape(Circle())
                    }
                    Button { 
                        renderAndShare()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.green.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 50)
                Spacer()
            }
            
            // Glassmorphic Floating Bar
            VStack {
                Spacer()
                Link(destination: URL(string: viewModel.product.url)!) {
                    HStack {
                        Text("Mağazada Görüntüle")
                            .fontWeight(.bold)
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        ZStack {
                            VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                            Color.blue.opacity(0.8)
                        }
                    )
                    .cornerRadius(30)
                    .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .task { 
            await viewModel.refreshData()
            await viewModel.loadAlternatives()
            await viewModel.fetchAnalysis()
        }
        .sheet(isPresented: $showCollectionSheet) {
            CollectionSelectionView(productId: viewModel.product.id)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: shareItems)
        }
        .alert("Ürünü Sil", isPresented: $showDeleteConfirmation) {
            Button("Sil", role: .destructive) {
                Task {
                    try? await viewModel.deleteProduct()
                    dismiss()
                }
            }
            Button("Vazgeç", role: .cancel) { }
        } message: {
            Text("Bu ürünü takipten çıkarmak istediğinize emin misiniz?")
        }
    }
    
    func scoreColor(_ score: Int) -> Color {
        if score >= 80 { return .green }
        if score >= 50 { return .orange }
        return .red
    }
    
    @MainActor
    private func renderAndShare() {
        // Create the view to render
        let cardView = ShareCardView(product: viewModel.product, brandColor: scoreColor(viewModel.opportunityScore))
        
        // Use ImageRenderer (iOS 16+)
        let renderer = ImageRenderer(content: cardView)
        renderer.scale = UIScreen.main.scale
        
        if let image = renderer.uiImage {
            // Also add the Deep Link URL
            let deepLink = URL(string: "https://firsatavcisi.com/product/\(viewModel.product.id)")!
            
            self.shareItems = [image, deepLink, "Fırsat Avcısı ile yakaladım! 🎯"]
            self.showShareSheet = true
        }
    }
}

// MARK: - Components

struct StatCard: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text("\(value, format: .currency(code: "TRY"))")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 5)
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
