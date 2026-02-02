import SwiftUI

struct MonthlyWrapView: View {
    let totalSavings: Double
    let bestCatch: Product?
    let hunterScore: Int
    @Binding var isPresented: Bool
    
    // Manage slides
    @State private var currentTab = 0
    let totalTabs = 4
    
    var body: some View {
        ZStack {
            // Dark Theme Background for Cinematic Feel
            Color.black.ignoresSafeArea()
            
            // Background Ambient Gradients
            GeometryReader { geo in
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100, y: -100)
                
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: geo.size.width - 150, y: geo.size.height - 150)
            }
            .ignoresSafeArea()
            
            // Main Content TabView
            TabView(selection: $currentTab) {
                // SLIDE 1: Intro & Savings
                WrapIntroView(savings: totalSavings) {
                    withAnimation { currentTab += 1 }
                }
                .tag(0)
                
                // SLIDE 2: Best Catch
                if let product = bestCatch {
                    WrapBestCatchView(product: product) {
                        withAnimation { currentTab += 1 }
                    }
                    .tag(1)
                } else {
                    // Fallback if no best catch, skip logically or show generic
                    WrapGenericView(title: "Henüz Av Yok", subtitle: "Gelecek ay senin olacak!") {
                        withAnimation { currentTab += 1 }
                    }
                    .tag(1)
                }
                
                // SLIDE 3: Hunter Score
                WrapScoreView(score: hunterScore) {
                    withAnimation { currentTab += 1 }
                }
                .tag(2)
                
                // SLIDE 4: Share Card
                WrapShareView(score: hunterScore, savings: totalSavings) {
                    isPresented = false
                }
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            // Progress Bar Overlay
            VStack {
                HStack(spacing: 4) {
                    ForEach(0..<totalTabs, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentTab ? Color.white : Color.white.opacity(0.3))
                            .frame(height: 4)
                            .frame(maxWidth: .infinity)
                            .animation(.default, value: currentTab)
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 20)
                
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Slide 1: Intro
struct WrapIntroView: View {
    let savings: Double
    let onNext: () -> Void
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("Bu Ay Harikaydın! 🌟")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .scaleEffect(animate ? 1 : 0.8)
                .opacity(animate ? 1 : 0)
            
            VStack(spacing: 12) {
                Text("Toplam Tasarrufun")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("\(Int(savings))₺")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: .green.opacity(0.5), radius: 20, x: 0, y: 0)
                    .scaleEffect(animate ? 1 : 0.5)
            }
            .opacity(animate ? 1 : 0)
            
            Text("Bu parayla neler alınmazdı ki? ☕️✈️")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .opacity(animate ? 1 : 0)
            
            Spacer()
            
            Button(action: onNext) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .shadow(radius: 10)
            }
            .padding(.bottom, 60)
            .opacity(animate ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(duration: 1.0)) {
                animate = true
            }
        }
    }
}

// MARK: - Slide 2: Best Catch
struct WrapBestCatchView: View {
    let product: Product
    let onNext: () -> Void
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("🏆 Ayın Avı")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.white)
                .offset(y: animate ? 0 : -50)
                .opacity(animate ? 1 : 0)
            
            ZStack {
                // Glow
                Circle()
                    .fill(Color.orange.opacity(0.4))
                    .frame(width: 300, height: 300)
                    .blur(radius: 50)
                
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 250, height: 250)
                .cornerRadius(20)
                .shadow(radius: 20)
                .rotation3DEffect(.degrees(animate ? 0 : 10), axis: (x: 0, y: 1, z: 0))
                
                // Discount Badge overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("%\(product.discountPercentage ?? 0)")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.white)
                            .padding(20)
                            .background(Circle().fill(Color.red))
                            .shadow(radius: 10)
                            .offset(x: 20, y: 20)
                    }
                }
                .frame(width: 250, height: 250)
            }
            .scaleEffect(animate ? 1 : 0.8)
            .opacity(animate ? 1 : 0)
            
            VStack {
                Text(product.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal)
                
                Text("Tam zamanında yakaladın.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .opacity(animate ? 1 : 0)
            
            Spacer()
            
            Button(action: onNext) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .shadow(radius: 10)
            }
            .padding(.bottom, 60)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8)) {
                animate = true
            }
        }
    }
}

// MARK: - Slide 3: Hunter Score
struct WrapScoreView: View {
    let score: Int // 0-100
    let onNext: () -> Void
    @State private var animate = false
    
    var rank: String {
        if score > 80 { return "EFSANE AVCI 🦖" }
        if score > 50 { return "KURT AVCI 🐺" }
        return "ÇIRAK AVCI 🐣"
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Avcılık Rütben")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            
            Text(rank)
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                .scaleEffect(animate ? 1 : 0.5)
                .opacity(animate ? 1 : 0)
            
            // Score Circle
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: animate ? CGFloat(score) / 100.0 : 0)
                    .stroke(
                        LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(score)")
                        .font(.system(size: 60, weight: .heavy))
                        .foregroundColor(.white)
                    Text("PUAN")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            Text("Reflekslerin çok sağlamdı.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            Button(action: onNext) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .shadow(radius: 10)
            }
            .padding(.bottom, 60)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                animate = true
            }
        }
    }
}

// MARK: - Slide 4: Share
struct WrapShareView: View {
    let score: Int
    let savings: Double
    let onDone: () -> Void
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Share Card
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "apple.logo") // Mock App Logo
                    Text("Fırsat Avcısı")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white.opacity(0.8))
                
                Divider().background(Color.white.opacity(0.3))
                
                VStack(spacing: 4) {
                    Text("OCAK AYI RAPORU")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(2)
                    
                    Text("\(Int(savings))₺ Tasarruf")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 20) {
                    VStack {
                        Text("Avcı Skoru")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(score)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 1, height: 40)
                    
                    VStack {
                        Text("Rütbe")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text("EFSANE")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(40)
            .background(
                LinearGradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(30)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .purple.opacity(0.5), radius: 30, x: 0, y: 10)
            .scaleEffect(animate ? 1 : 0.9)
            .opacity(animate ? 1 : 0)
            
            Button(action: onDone) {
                Text("Kapat ve Paylaş")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 10)
            }
            .opacity(animate ? 1 : 0)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(duration: 1.0)) {
                animate = true
            }
        }
    }
}

// Generic Backup
struct WrapGenericView: View {
    let title: String
    let subtitle: String
    let onNext: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            Text(title).font(.largeTitle).foregroundColor(.white)
            Text(subtitle).foregroundColor(.gray)
            Spacer()
            Button(action: onNext) {
                Image(systemName: "arrow.right.circle.fill").font(.system(size: 60)).foregroundColor(.white)
            }
            .padding(.bottom, 60)
        }
    }
}
