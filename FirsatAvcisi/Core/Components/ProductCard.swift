import SwiftUI

struct ProductCard: View {
    let product: Product
    var onQuickAdd: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection
            infoSection
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Subviews
    
    private var imageSection: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: URL(string: product.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.1)
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .clipped()
            .background(Color.white)
            
            // Priority: Inditex discount (originalPrice) -> History discount
            if let original = product.originalPrice, original > product.currentPrice {
                discountBadge(original: original, current: product.currentPrice)
            } else if let history = product.history, let first = history.first, first.price > product.currentPrice {
                discountBadge(original: first.price, current: product.currentPrice)
            }
        }
        .background(Color.white)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(product.title)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(height: 36, alignment: .topLeading)
                .foregroundColor(.primary)
            
            // Store
            Text(product.source.capitalized)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom) {
                priceView
                Spacer()
                addButton
            }
        }
        .padding(10)
    }
    
    private var priceView: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Original Price (Strikethrough)
            if let original = product.originalPrice, original > product.currentPrice {
                Text("\(original, format: .currency(code: "TRY"))")
                    .font(.system(size: 11, weight: .regular))
                    .strikethrough()
                    .foregroundColor(.secondary)
            } else if let history = product.history, let first = history.first, first.price > product.currentPrice {
                 Text("\(first.price, format: .currency(code: "TRY"))")
                    .font(.system(size: 11, weight: .regular))
                    .strikethrough()
                    .foregroundColor(.secondary)
            }
            
            // Current Price
            if product.currentPrice > 0 {
                Text("\(product.currentPrice, format: .currency(code: "TRY"))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(product.originalPrice != nil && product.originalPrice! > product.currentPrice ? .red : .black)
            } else {
                Text("Fiyat Gör")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
            }
        }
    }
    
    @ViewBuilder
    private var addButton: some View {
        if let onQuickAdd = onQuickAdd {
            Button(action: onQuickAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func discountBadge(original: Double, current: Double) -> some View {
        let discount = Int(((original - current) / original) * 100)
        return Text("%\(discount)")
            .font(.system(size: 11, weight: .bold))
            .padding(6)
            .background(Color.red)
            .foregroundColor(.white)
            .clipShape(Circle())
            .padding(8)
    }
}
