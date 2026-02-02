import SwiftUI

struct AddProductView: View {
    @StateObject private var viewModel = AddProductViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showScanner = false
    
    
    var preview: AddProductViewModel.ProductPreview? = nil // Optional preview product from other screens
    
    // Modern Gradient
    private let backgroundGradient = LinearGradient(colors: [Color.black, Color(uiColor: .darkGray)], startPoint: .top, endPoint: .bottom)
    
    var body: some View {
        ZStack {
            // Background
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                HStack {
                    Text("Yeni Fırsat Ekle")
                        .font(.system(size: 28, weight: .bold))
                    Spacer()
                    
                    Button {
                        showScanner = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(Color.white.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal)
                
                // Input Card
                VStack(spacing: 20) {
                    Text("Ürün Linkini Yapıştır")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.blue)
                        TextField("https://trendyol.com/...", text: $viewModel.url)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    
                    Button {
                        Task { await viewModel.analyzeLink() }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 5)
                                Text("Analiz Ediliyor...")
                            } else {
                                Text("Linki Analiz Et")
                                Image(systemName: "wand.and.stars")
                            }
                        }
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .disabled(viewModel.url.isEmpty || viewModel.isLoading)
                    .opacity(viewModel.url.isEmpty ? 0.6 : 1)
                }
                .padding()
                
                // Result / Preview Area
                if let preview = viewModel.previewProduct {
                    VStack(spacing: 0) {
                        // Success Header
                        HStack {
                            Text("Ürün Bulundu! 🎉")
                                .font(.headline)
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        
                        HStack(spacing: 16) {
                            AsyncImage(url: URL(string: preview.imageUrl)) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.2)
                            }
                            .frame(width: 80, height: 80)
                            .cornerRadius(12)
                            .clipped()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preview.source.uppercased())
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                
                                Text(preview.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .lineLimit(2)
                                
                                Text("\(preview.currentPrice, format: .currency(code: "TRY"))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        
                        Divider()
                        
                        Button {
                            Task { await viewModel.saveProduct() }
                        } label: {
                            Text("Takip Listesine Ekle")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.black)
                                .foregroundColor(.white)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
        }
        .onAppear {
            if let p = preview {
                viewModel.previewProduct = p
                viewModel.url = p.url
            }
        }
        .onChange(of: viewModel.shouldDismiss) { _, newValue in
            if newValue { dismiss() }
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showScanner) {
            BarcodeScannerView()
        }
    }
}
