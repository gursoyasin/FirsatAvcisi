import SwiftUI

struct SmartDashboardView: View {
    @StateObject private var viewModel = SmartDashboardViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Binding var currentTab: Tab
    
    // Animation States
    @State private var ringTrim: CGFloat = 0.0
    @State private var isBreathing = false
    @State private var gradientStart = UnitPoint(x: 0, y: 0)
    @State private var gradientEnd = UnitPoint(x: 0, y: 2)
    @State private var showAddSheet = false // Magic Add Sheet
    @State private var showNotifications = false
    @State private var showProfile = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {


                // 1. LIVE MESH GRADIENT BACKGROUND
                LiveBackgroundView()
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // 2. MOOD HEADER (Now with Bell)
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                TypingTextView(fullText: viewModel.moodMessage)
                                    .font(.system(size: 26, weight: .semibold, design: .serif))
                                    .lineSpacing(4)
                                    .foregroundColor(.primary)
                                
                                Text("Bugün, \(Date().formatted(.dateTime.day().month(.wide)))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .kerning(1.5)
                                    .opacity(0.8)
                            }
                            
                            Spacer()
                            
                            // Profile & Bell Buttons
                            HStack(spacing: 12) {
                                Button(action: { showProfile = true }) {
                                    Image(systemName: "person.crop.circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(.primary)
                                        .padding(10)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                                
                                Button(action: { showNotifications = true }) {
                                    Image(systemName: "bell.badge.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.primary)
                                        .padding(10)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 24)
                        
                        // 3. DYNAMIC WAITING RING
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .stroke(lineWidth: 3)
                                    .foregroundColor(Color.black.opacity(0.05))
                                    .frame(width: 50, height: 50)
                                
                                Circle()
                                    .trim(from: 0.0, to: ringTrim)
                                    .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                    .foregroundColor(.blue)
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 50, height: 50)
                                    .shadow(color: .blue.opacity(0.5), radius: 4, x: 0, y: 0) // Glow
                                
                                Text("\(viewModel.averageWaitingTime)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Ortalama Bekleme Süren")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("~ \(viewModel.averageWaitingTime) Gün")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                Text("En iyi indirimler genelde 5-9 gün içinde gelir")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(20)
                        .background(.ultraThinMaterial) // Glassmorphism
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 10)
                        .padding(.horizontal)
                        .onAppear {
                            withAnimation(.easeOut(duration: 1.5).delay(0.5)) {
                                // Calculate trim based on 10 days max (example)
                                ringTrim = CGFloat(viewModel.averageWaitingTime) / 10.0
                            }
                        }
                        
                        // 4. EMOTIONAL FEED (BREATHING EFFECT)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("BUGÜN KALBİNDE OLANLAR")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .kerning(1)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            ForEach(viewModel.emotionalFeed) { product in
                                NavigationLink(destination: ProductDetailView(product: product)) {
                                    EmotionalProductCard(product: product, viewModel: viewModel)
                                        .offset(y: isBreathing ? -3 : 3)
                                        .animation(
                                            .easeInOut(duration: 3).repeatForever(autoreverses: true).delay(Double.random(in: 0...1)),
                                            value: isBreathing
                                        )
                                }
                                .buttonStyle(PlainButtonStyle()) // Needed for Heart Button tap
                            }
                        }
                        .onAppear { isBreathing = true }
                        
                        // 5. "SENİN TARZINDA BUGÜN"
                        if let dailyPick = viewModel.dailyDiscountPick {
                            VStack(spacing: 0) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.yellow)
                                        .symbolEffect(.bounce, value: isBreathing) // iOS 17 Symbol Effect
                                    Text("Senin Tarzında Bugün")
                                        .font(.headline)
                                    Spacer()
                                }
                                .padding()
                                
                                Divider()
                                
                                HStack(spacing: 16) {
                                    AsyncImage(url: URL(string: dailyPick.imageUrl ?? "")) { image in
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Color.gray.opacity(0.2)
                                    }
                                    .frame(width: 80, height: 100)
                                    .clipped()
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(dailyPick.title)
                                            .font(.subheadline)
                                            .lineLimit(2)
                                        
                                        HStack {
                                            Text("\(Int(dailyPick.currentPrice))₺")
                                                .fontWeight(.bold)
                                            if let old = dailyPick.originalPrice {
                                                Text("\(Int(old))₺")
                                                    .strikethrough()
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Text("Bu ürün senin için seçildi")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .padding()
                                }
                                .padding()
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    HapticManager.shared.impact(style: .light)
                                    currentTab = .inditex
                                }
                            }
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .padding(.horizontal)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        }
                        
                        // 6. NATIVE AD (REKLAM)
                        NativeAdCard()
                            .padding(.vertical)
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.top)
                }
                
                // 6. FLOATING BUTTON
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            HapticManager.shared.impact(style: .heavy)
                            showAddSheet = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("Ürün Linki Ekle")
                                        .font(.system(size: 15, weight: .bold))
                                    Text("Biz bekleriz.")
                                        .font(.system(size: 11, weight: .regular))
                                        .opacity(0.9)
                                }
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 24)
                            .foregroundColor(.white)
                            .background(
                                LinearGradient(colors: [.black, Color(uiColor: .darkGray)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(35)
                            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 35)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(.bottom, 90)
                        .padding(.trailing, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAddSheet) {
            SmartAddSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showNotifications) {
            NotificationListView()
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
    }
}

// MARK: - PREMIUM COMPONENTS

struct LiveBackgroundView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Base Color
            Color(uiColor: .systemGroupedBackground)
            
            // 1. Moving Blob (Cyan)
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: animate ? -100 : 100, y: animate ? -50 : 50)
                .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animate)
            
            // 2. Moving Blob (Purple)
            Circle()
                .fill(Color.purple.opacity(0.15))
                .frame(width: 350, height: 350)
                .blur(radius: 70)
                .offset(x: animate ? 100 : -100, y: animate ? 100 : -100)
                .animation(.easeInOut(duration: 12).repeatForever(autoreverses: true), value: animate)
            
            // 3. Moving Blob (Orange - Minimal)
            Circle()
                .fill(Color.orange.opacity(0.1))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(x: animate ? -50 : 50, y: animate ? 150 : -50)
                .animation(.easeInOut(duration: 15).repeatForever(autoreverses: true), value: animate)
        }
        .onAppear {
            animate = true
        }
    }
}

struct TypingTextView: View {
    let fullText: String
    @State private var textToDisplay = ""
    
    var body: some View {
        Text(textToDisplay)
            .task(id: fullText) { // Re-runs when fullText changes
                textToDisplay = ""
                await typeText(content: fullText)
            }
    }
    
    func typeText(content: String) async {
        for (index, character) in content.enumerated() {
            // Check for cancellation implicitly via Task.sleep behavior or check Task.isCancelled if needed
            // But just sleeping inside the loop is usually enough as SwiftUI cancels the task
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s
            
            if Task.isCancelled { return }
            
            textToDisplay.append(character)
            
            if index % 3 == 0 {
                HapticManager.shared.impact(style: .soft)
            }
        }
    }
}

// MARK: - Emotional Product Card
struct EmotionalProductCard: View {
    let product: Product
    let viewModel: SmartDashboardViewModel
    @State private var isLiked: Bool = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .top, spacing: 16) {
                // Image
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 100, height: 130)
                .cornerRadius(16)
                .clipped()
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Social Proof Badge
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                        Text("\(product.followerCount ?? 0) kişi seninle bekliyor")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                    
                    Text(product.title)
                        .font(.system(size: 15, weight: .medium))
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    // Smart Probability
                    HStack(spacing: 6) {
                        Circle()
                            .fill(viewModel.getProbabilityColor(score: product.smartScore ?? 0.5))
                            .frame(width: 8, height: 8)
                            .shadow(color: viewModel.getProbabilityColor(score: product.smartScore ?? 0.5).opacity(0.5), radius: 3)
                        
                        Text(viewModel.getProbabilityText(score: product.smartScore ?? 0.5))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Price
                    HStack {
                        Text("\(Int(product.currentPrice))₺")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        
                        if let old = product.originalPrice {
                            Text("\(Int(old))₺")
                                .strikethrough()
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 6)
                
                Spacer()
            }
            .padding(12)
            .background(.ultraThinMaterial) // High-end feel
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
            .padding(.horizontal)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            
            // Heart Button
            Button(action: {
                HapticManager.shared.impact(style: .medium)
                isLiked.toggle()
                WatchlistManager.shared.toggleWatchlist(product: product)
            }) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 20))
                    .foregroundColor(isLiked ? .red : .gray)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            .padding(.top, 10)
            .padding(.trailing, 25) // Adjust for padding
        }
        .onAppear {
            isLiked = WatchlistManager.shared.isWatching(productId: product.id)
        }
    }
}
