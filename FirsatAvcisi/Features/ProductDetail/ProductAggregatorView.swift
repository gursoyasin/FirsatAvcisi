import SwiftUI

struct ProductAggregatorView: View {
    let product: Product
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    // Sort sellers by price ascending
    var sortedSellers: [Seller] {
        if let sellers = product.sellers, !sellers.isEmpty {
            // Only show VALID sellers (must have price and name)
            return sellers.compactMap { seller -> Seller? in
                guard let price = seller.price, let name = seller.merchant else { return nil }
                return seller
            }.sorted { ($0.price ?? 0) < ($1.price ?? 0) }
        } else {
            // Fallback: This is the MAIN product source, so it is "Real"
            return [
                Seller(
                    merchant: product.source.capitalized, 
                    price: product.currentPrice, 
                    url: product.url, 
                    badge: "En İyi Fiyat"
                )
            ]
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Header Section
                VStack(spacing: 16) {
                    // Hero Image
                    ZStack(alignment: .topTrailing) {
                        AsyncImage(url: URL(string: product.imageUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(height: 250)
                        
                        // Rating Badge
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 12))
                            Text("8.9") // Mock rating or calculated
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.blue)
                        .clipShape(Capsule())
                        .padding()
                    }
                    
                    // Title & Category
                    VStack(alignment: .leading, spacing: 8) {
                        if let cat = product.category {
                            Text(cat.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        Text(product.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                
                // MARK: - Best Price Highlight
                VStack(alignment: .leading, spacing: 12) {
                    Text("EN İYİ FİYAT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    HStack {
                        Text(product.currentPrice, format: .currency(code: "TRY"))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            // Primary Link: Go to best seller directly
                            if let bestSellerUrl = sortedSellers.first?.url, let url = URL(string: bestSellerUrl) {
                                openURL(url)
                            } else if let url = URL(string: product.url) {
                                openURL(url)
                            }
                        }) {
                            Text("Mağazaya Git")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    
                    Text("\(product.source.capitalized) üzerinden satılıyor")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // MARK: - Variants Section
                if let variants = product.variants, !variants.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Seçenekler")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(variants) { variant in
                                    Button(action: {
                                        // Open variant URL
                                        if let urlString = variant.url, let url = URL(string: urlString) {
                                            openURL(url)
                                        }
                                    }) {
                                        Text(variant.title ?? "Seçenek")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color(.systemBackground))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // MARK: - Sellers List
                if !sortedSellers.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Diğer Satıcılar (\(sortedSellers.count))")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(sortedSellers) { seller in
                                SellerRow(seller: seller)
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                     VStack(spacing: 16) {
                        Image(systemName: "tag.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Başka satıcı bulunamadı.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Bu ürün için şu an tek fiyat mevcut.")
                            .font(.caption)
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(Color(.secondarySystemBackground).opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 50)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SellerRow: View {
    let seller: Seller
    @Environment(\.openURL) var openURL
    
    var body: some View {
        HStack {
            // Source Logo/Icon Placeholder
            Circle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Text((seller.merchant ?? "").prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                // Safe display
                Text(seller.merchant ?? "")
                    .font(.body)
                    .fontWeight(.medium)
                
                if let badge = seller.badge {
                    Text(badge)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(seller.price ?? 0, format: .currency(code: "TRY"))
                    .font(.headline)
                
                Button(action: {
                    if let urlString = seller.url, let url = URL(string: urlString) {
                        openURL(url)
                    }
                }) {
                    Text("Git")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
