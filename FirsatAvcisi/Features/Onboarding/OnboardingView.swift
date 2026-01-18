import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    let slides = [
        OnboardingSlide(
            image: "sparkles.rectangle.stack",
            title: "Fırsatları Yakala",
            description: "Takip ettiğin ürünlerin fiyatlarını senin için izliyoruz. İndirim geldiğinde hemen haber veriyoruz."
        ),
        OnboardingSlide(
            image: "square.and.arrow.up",
            title: "Kolayca Ekle",
            description: "Safari veya başka bir uygulamadan paylaşım eklentisini kullanarak saniyeler içinde ürün ekle."
        ),
        OnboardingSlide(
            image: "folder.badge.plus",
            title: "Akıllı Klasörler",
            description: "Ürünlerini kategorize et veya akıllı koleksiyonlar ile fırsatları topluca yönet."
        )
    ]
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button("Atla") {
                        completeOnboarding()
                    }
                    .foregroundColor(.secondary)
                    .padding()
                }
                
                TabView(selection: $currentPage) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        SlideView(slide: slides[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                Button(action: {
                    if currentPage < slides.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        completeOnboarding()
                    }
                }) {
                    Text(currentPage == slides.count - 1 ? "Başlayalım" : "Devam Et")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
            }
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        withAnimation {
            isPresented = false
        }
    }
}

struct OnboardingSlide {
    let image: String
    let title: String
    let description: String
}

struct SlideView: View {
    let slide: OnboardingSlide
    
    var body: some View {
        VStack(spacing: 40) {
            Image(systemName: slide.image)
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .frame(height: 120)
            
            VStack(spacing: 16) {
                Text(slide.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(slide.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
