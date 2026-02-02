import SwiftUI
import Combine

struct TargetPriceSheet: View {
    let product: Product
    @Environment(\.dismiss) var dismiss
    @State private var targetPrice: String = ""
    @State private var isLoading = false
    @State private var sliderValue: Double = 0
    
    // Impact Generators
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    
    var currentPrice: Double { product.currentPrice }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                Spacer().frame(height: 20)
                
                // Header
                Text("Hedef Fiyatını Belirle")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                
                Text(product.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .padding(.top, 4)
                
                Spacer()
                
                // Main Input (Big Number)
                VStack(spacing: 8) {
                    Text("Şu an: \(Int(currentPrice)) TL")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                    
                    HStack(spacing: 4) {
                        Text("₺")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.primary)
                        
                        TextField("0", text: $targetPrice)
                            .keyboardType(.numberPad)
                            .font(.system(size: 48, weight: .heavy, design: .rounded))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: true, vertical: true)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(24)
                    
                    Text("Bu fiyata düşünce bildirim alacaksın.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Smart Suggestions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Akıllı Öneriler")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            SuggestionPill(percent: 10, current: currentPrice) { val in setPrice(val) }
                            SuggestionPill(percent: 20, current: currentPrice) { val in setPrice(val) }
                            SuggestionPill(percent: 30, current: currentPrice) { val in setPrice(val) }
                            SuggestionPill(percent: 50, current: currentPrice) { val in setPrice(val) }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
                
                // Save Button
                Button(action: saveTargetPrice) {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "bell.fill")
                            Text("Alarmı Kur")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(isValid ? Color.blue : Color.gray.opacity(0.3))
                    .cornerRadius(18)
                    .shadow(color: isValid ? .blue.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)
                }
                .disabled(!isValid || isLoading)
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            if let existing = product.targetPrice, existing > 0 {
                targetPrice = "\(Int(existing))"
            }
        }
        .onChange(of: targetPrice) { _, _ in
            HapticManager.shared.impact(style: .light)
        }
    }
    
    var isValid: Bool {
        guard let value = Double(targetPrice) else { return false }
        return value < currentPrice && value > 0
    }
    
    func setPrice(_ value: Double) {
        targetPrice = "\(Int(value))"
        HapticManager.shared.impact(style: .medium)
    }
    
    func saveTargetPrice() {
        guard let price = Double(targetPrice) else { return }
        isLoading = true
        HapticManager.shared.impact(style: .heavy)
        
        Task {
            do {
                try await APIService.shared.setTargetPrice(productId: product.id, price: price)
                HapticManager.shared.notification(type: .success)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                print("Failed: \(error)")
                await MainActor.run { isLoading = false }
            }
        }
    }
}

struct SuggestionPill: View {
    let percent: Int
    let current: Double
    let action: (Double) -> Void
    
    var value: Double {
        current * (1.0 - Double(percent) / 100.0)
    }
    
    var body: some View {
        Button(action: { action(value) }) {
            VStack(spacing: 2) {
                Text("-% \(percent)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
                
                Text("\(Int(value))₺")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
    }
}
