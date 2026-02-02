import SwiftUI
import Charts

// MARK: - Hunter Header View (Dynamic Greeting)
struct HunterHeaderView: View {
    @State private var timeGreeting: String = ""
    @Binding var showingNotifications: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeGreeting)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(LocalizedStringKey("dashboard.title")) // Using Localized Key
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            Spacer()
            
            // Profile / Notification Button
            Button(action: { showingNotifications = true }) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .padding(10)
                    .background(Material.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .onAppear {
            updateGreeting()
        }
    }
    
    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: timeGreeting = "Günaydın, Avcı! ☀️"
        case 12..<18: timeGreeting = "Tünaydın, Avcı! 👋"
        case 18..<22: timeGreeting = "İyi Akşamlar, Avcı! 🌙"
        default: timeGreeting = "İyi Geceler, Avcı! 🦉"
        }
    }
}

// MARK: - Hunt Stats View (Horizontal Carousel)
struct HuntStatsView: View {
    let savedAmount: Double // Demo purposes
    let onSaleCount: Int
    let trackingCount: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Savings Card
                PremiumStatCard(
                    title: "Toplam Tasarruf",
                    value: String(format: "%.0f₺", savedAmount),
                    icon: "arrow.down.right.circle.fill",
                    gradient: LinearGradient(colors: [Color.green.opacity(0.8), Color.teal.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                
                // On Sale Card
                PremiumStatCard(
                    title: "İndirimde",
                    value: "\(onSaleCount) Ürün",
                    icon: "flame.fill",
                    gradient: LinearGradient(colors: [Color.orange.opacity(0.8), Color.red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                
                // Tracking Card
                PremiumStatCard(
                    title: "Takipte",
                    value: "\(trackingCount) Ürün",
                    icon: "eye.fill",
                    gradient: LinearGradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}

struct PremiumStatCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
            
            Spacer()
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(12)
        .frame(width: 140, height: 100)
        .background(gradient)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Premium Filter Chip
struct PremiumFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14, weight: .bold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected ?
                Color.blue :
                Color(uiColor: .secondarySystemBackground)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
            .shadow(
                color: isSelected ? Color.blue.opacity(0.3) : Color.clear,
                radius: 8, x: 0, y: 4
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - SHARED SUBVIEWS

struct ProductGridCard: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.1)
                        ProgressView().scaleEffect(0.5)
                    }
                }
                .frame(height: 170)
                .clipped()
                .background(Color(uiColor: .systemGray6))
                
                // Discount Badge (Glass)
                if let history = product.history, let first = history.first, first.price > product.currentPrice {
                     let discount = Int(((first.price - product.currentPrice) / first.price) * 100)
                     Text("%\(discount) İNDİRİM")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding(8)
                }
                
                // Stock Badge
                if let inStock = product.inStock, !inStock {
                    Text("STOK YOK")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(4)
                        .padding(8)
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                // Store Source
                Text(product.source.uppercased())
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.secondary)
                
                Text(product.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(2)
                    .frame(height: 34, alignment: .topLeading)
                    .foregroundColor(.primary)
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(product.currentPrice, format: .currency(code: "TRY"))")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(.blue)
                            .minimumScaleFactor(0.5) // FIX: Aggressive scaling for large prices
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Small Sparkline
                    if let history = product.history, history.count > 1 {
                        Chart(history) {
                            LineMark(x: .value("D", $0.checkedAt), y: .value("P", $0.price))
                                .foregroundStyle(Color.green.gradient)
                                .interpolationMethod(.catmullRom)
                        }
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                        .frame(width: 40, height: 20)
                    }
                }
            }
            .padding(12)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

struct BadgeView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color)
            .cornerRadius(4)
    }
}

// Helper to wrap grid cards with selection logic
struct ProductContainer: View {
    let product: Product
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.isEditMode {
                ProductGridCard(product: product)
                    .onTapGesture {
                        viewModel.toggleSelection(for: product.id)
                    }
                
                Image(systemName: viewModel.selectedProductIDs.contains(product.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(.blue)
                    .background(Color.white.clipShape(Circle()))
                    .padding(8)
            } else {
                NavigationLink(destination: ProductDetailView(product: product)) {
                    ProductGridCard(product: product)
                }
            }
        }
    }
}

struct EditOverlay: View {
    let selectedCount: Int
    let onDelete: () -> Void
    let onAddToCollection: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 20) {
                Button(action: onAddToCollection) {
                    VStack(spacing: 4) {
                        Image(systemName: "folder.badge.plus")
                        Text("Klasöre Ekle").font(.caption2)
                    }
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Text("\(selectedCount) seçildi")
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: onDelete) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Sil").font(.caption2)
                    }
                }
                .foregroundColor(.red)
                
                Button(action: onCancel) {
                   Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Material.thinMaterial)
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding()
        }
    }
}

struct CollectionSelectionSheet: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    @State private var newCollectionName = ""
    
    var body: some View {
        NavigationView {
            List {
                Section("Koleksiyonlarım") {
                    ForEach(viewModel.collections) { collection in
                        Button {
                            Task {
                                await viewModel.addToCollection(collectionId: collection.id)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                .foregroundColor(.blue)
                                Text(collection.name)
                                Spacer()
                                Text("\(collection._count?.products ?? 0) ürün")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Yeni Oluştur") {
                    HStack {
                        TextField("Koleksiyon adı...", text: $newCollectionName)
                        Button("Ekle") {
                            // Logic to create and then add? Or just create.
                            // For simplicity, just add to existing or create new logic later.
                        }
                        .disabled(newCollectionName.isEmpty)
                    }
                }
            }
            .navigationTitle("Klasör Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

struct GlobalSearchCard: View {
    let product: GlobalSearchProduct
    @State private var isAdding = false
    @State private var added = false
    @State private var isResolvingURL = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main clickable area
            Button(action: {
                Task {
                    await openStoreURL(product.url)
                }
            }) {
                VStack(alignment: .leading, spacing: 0) {
                    // Image Area with Premium Overlays
                    ZStack(alignment: .topTrailing) {
                        AsyncImage(url: URL(string: product.imageUrl ?? "")) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ZStack {
                                Color(uiColor: .systemGray6)
                                ProgressView().scaleEffect(0.8)
                            }
                        }
                        .frame(width: 180, height: 180)
                        .clipped()
                        
                        // Top Right: Main Store Badge
                        VStack {
                            Text(product.source.uppercased())
                                .font(.system(size: 9, weight: .heavy))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(sourceColor.opacity(0.95))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .padding(8)
                            Spacer()
                        }
                        
                        // Bottom Left: Price Insight Badge
                        if let badge = product.badge {
                            VStack {
                                Spacer()
                                HStack {
                                    Text(badge)
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 4)
                                        .background(Color.black.opacity(0.85))
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                        .padding(8)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .frame(width: 180, height: 180)
                    .background(Color.white)
                    
                    // Info Area
                    VStack(alignment: .leading, spacing: 5) {
                        Text(product.title)
                            .font(.system(size: 13, weight: .bold))
                            .lineLimit(2)
                            .foregroundColor(.primary)
                            .frame(height: 38, alignment: .topLeading)
                            .padding(.top, 4)
                        
                        // Store Name (User Request)
                        HStack {
                            Image(systemName: "bag.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text(product.source.capitalized)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(alignment: .bottom) {
                            Text("\(product.currentPrice, specifier: "%.2f") TL")
                                .font(.system(size: 17, weight: .black))
                                .foregroundColor(.blue)
                                .minimumScaleFactor(0.5) // FIX
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if let offers = product.sellers, offers.count > 1 {
                                Text("\(offers.count) mağaza")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                        
                        // Mini Comparison View (If multiple offers exist)
                        if let offers = product.sellers, offers.count > 1 {
                            VStack(alignment: .leading, spacing: 4) {
                                Divider().padding(.vertical, 4)
                                
                                ForEach(offers.prefix(2)) { offer in
                                    HStack {
                                        Circle()
                                            .fill(offerColor(for: offer.displaySource))
                                            .frame(width: 6, height: 6)
                                        Text(offer.displaySource.capitalized)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(offer.price, specifier: "%.0f")₺")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.bottom, 4)
                        }
                    }
                    .padding(12)
                    .contentShape(Rectangle())
                }
            }
            .buttonStyle(.plain)
            .overlay {
                if isResolvingURL {
                    ZStack {
                        Color.black.opacity(0.1)
                        ProgressView("Mağazaya Gidiliyor...")
                            .font(.system(size: 10, weight: .bold))
                            .padding()
                            .background(Material.thinMaterial)
                            .cornerRadius(12)
                    }
                }
            }
            
            // Add Button with Animation (OUTSIDE main clickable area)
            Button(action: {
                Task {
                    await addToTracker()
                }
            }) {
                HStack(spacing: 6) {
                    if isAdding {
                        ProgressView().tint(.white).scaleEffect(0.7)
                    } else {
                        Image(systemName: added ? "checkmark" : "plus.circle.fill")
                        Text(added ? "Takipte" : "Hemen Takibe Al")
                    }
                }
                .font(.system(size: 11, weight: .black))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(added ? Color.green : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: (added ? Color.green : Color.blue).opacity(0.2), radius: 5, x: 0, y: 3)
            }
            .disabled(isAdding || added)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 180)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 8)
    }
    
    var sourceColor: Color {
        offerColor(for: product.source)
    }
    
    private func offerColor(for source: String) -> Color {
        let src = source.lowercased()
        if src.contains("amazon") { return .orange }
        if src.contains("trendyol") { return .orange }
        if src.contains("hepsi") { return .blue }
        if src.contains("n11") { return .red }
        if src.contains("cimri") { return .blue }
        if src.contains("pazarama") { return .purple }
        if src.contains("çiçek") { return .pink }
        return .gray
    }
    
    private func addToTracker() async {
        isAdding = true
        do {
            try await APIService.shared.addProduct(preview: product.toPreview)
            added = true
            // Haptic Feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            print("Search add error: \(error.localizedDescription)")
        }
        isAdding = false
    }
    
    private func openStoreURL(_ initialUrl: String) async {
        guard !isResolvingURL else { return }
        isResolvingURL = true
        
        do {
            let finalUrlString = try await APIService.shared.resolveURL(url: initialUrl)
            if let finalURL = URL(string: finalUrlString) {
                await MainActor.run {
                    UIApplication.shared.open(finalURL)
                }
            }
        } catch {
            if let fallbackURL = URL(string: initialUrl) {
                await UIApplication.shared.open(fallbackURL)
            }
        }
        isResolvingURL = false
    }
}

struct GlobalSearchCardSkeleton: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Placeholder Image with Shimmer
            Rectangle()
                .fill(Color(uiColor: .systemGray6))
                .overlay(
                    GeometryReader { geo in
                        Color.white.opacity(0.3)
                            .mask(
                                Rectangle()
                                    .fill(
                                        LinearGradient(gradient: .init(colors: [.clear, .white.opacity(0.5), .clear]), startPoint: .leading, endPoint: .trailing)
                                    )
                                    .offset(x: -geo.size.width + (phase * (geo.size.width * 2)))
                            )
                    }
                )
                .frame(width: 180, height: 180)
            
            VStack(alignment: .leading, spacing: 8) {
                // Title Lines
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .systemGray5))
                    .frame(height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 120, height: 14)
                
                // Price
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 80, height: 20)
                    .padding(.top, 4)
                
                // Button
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .systemGray5))
                    .frame(height: 36)
                    .padding(.top, 8)
            }
            .padding(12)
        }
        .frame(width: 180)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 1.0
            }
        }
    }
}
