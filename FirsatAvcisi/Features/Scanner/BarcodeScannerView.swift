import SwiftUI

struct BarcodeScannerView: View {
    @State private var isScanning = true
    @State private var scannedCode: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var foundProduct: AddProductViewModel.ProductPreview?
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                if let product = foundProduct {
                    // Show result
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                            .padding()
                        
                        Text("Ürün Bulundu!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        AsyncImage(url: URL(string: product.imageUrl)) { img in
                            img.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Color.gray.opacity(0.1)
                        }
                        .frame(height: 200)
                        .cornerRadius(12)
                        .padding()
                        
                        Text(product.title)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text("\(product.currentPrice, format: .currency(code: "TRY"))")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        NavigationLink(destination: AddProductView(preview: product)) {
                            Text("Listeme Ekle")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding()
                    }
                } else {
                    // Camera
                    ZStack {
                        ScannerView { code in
                            handleScan(code: code)
                        }
                        .ignoresSafeArea()
                        
                        // Overlay
                        VStack {
                            Spacer()
                            Text("Barkodu Kutuya Getir")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                                .padding(.bottom, 50)
                        }
                        
                        if isLoading {
                            Color.black.opacity(0.4).ignoresSafeArea()
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.white)
                                Text("Ürün aranıyor...")
                                    .foregroundColor(.white)
                                    .padding(.top)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Barkod Tara")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
            .alert("Hata", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
                Button("Tamam", role: .cancel) {
                    isScanning = true // Resume
                    scannedCode = nil
                }
            } message: {
                Text(errorMessage ?? "Bir hata oluştu")
            }
        }
    }
    
    private func handleScan(code: String) {
        guard !isLoading && scannedCode == nil else { return }
        scannedCode = code
        isScanning = false
        isLoading = true
        
        // Setup timer to simulate network or actually call API
        Task {
            do {
                let product = try await APIService.shared.lookupBarcode(barcode: code)
                self.foundProduct = product
                self.isLoading = false
            } catch {
                self.errorMessage = "Ürün bulunamadı. Lütfen tekrar deneyin."
                self.isLoading = false
                self.scannedCode = nil // Reset to allow retry
            }
        }
    }
}
