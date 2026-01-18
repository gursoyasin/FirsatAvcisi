import SwiftUI

struct CollectionsView: View {
    @StateObject private var viewModel = CollectionsViewModel()
    
    // Grid Layout: 2 Columns
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.collections.isEmpty {
                    // Skeleton Loading State
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Yükleniyor...")
                                .font(.headline)
                                .padding(.horizontal)
                                .redacted(reason: .placeholder)
                                .skeleton(isLoading: true)
                            
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(0..<6, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .frame(height: 200)
                                        .skeleton(isLoading: true)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Smart Collections Section
                            let smarts = viewModel.collections.filter { $0.type == "SMART" }
                            if !smarts.isEmpty {
                                Text("Akıllı Listeler")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(smarts) { collection in
                                            NavigationLink(destination: CollectionDetailView(collectionId: collection.id, collectionName: collection.name)) {
                                                SmartCollectionCard(collection: collection)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            Text("Koleksiyonlarım")
                                .font(.headline)
                                .padding(.horizontal)

                            if viewModel.collections.filter({ $0.type == "MANUAL" }).isEmpty {
                                 EmptyStateView(
                                     icon: "folder.badge.plus",
                                     title: "Koleksiyonun Yok",
                                     message: "Ürünlerini daha kolay bulmak için klasörler oluşturabilirsin.",
                                     buttonTitle: "Yeni Kaydet",
                                     action: { viewModel.showAddSheet = true }
                                 )
                                 .padding(.top, 40)
                            } else {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(viewModel.collections.filter({ $0.type == "MANUAL" })) { collection in
                                        NavigationLink(destination: CollectionDetailView(collectionId: collection.id, collectionName: collection.name)) {
                                            CollectionCard(collection: collection)
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                viewModel.deleteCollection(id: collection.id)
                                            } label: {
                                                Label("Sil", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        viewModel.loadCollections()
                    }
                }
            }
            .navigationTitle("Koleksiyonlar")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddSheet) {
                NavigationView {
                    Form {
                        Section("Temel Bilgiler") {
                            TextField("Koleksiyon Adı", text: $viewModel.newCollectionName)
                            Toggle("Herkese Açık", isOn: $viewModel.isPublic)
                        }
                        
                        Section("İkon Seçimi") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(viewModel.icons, id: \.self) { icon in
                                        Image(systemName: icon)
                                            .font(.title2)
                                            .foregroundColor(viewModel.selectedIcon == icon ? .white : .blue)
                                            .frame(width: 44, height: 44)
                                            .background(viewModel.selectedIcon == icon ? Color.blue : Color.blue.opacity(0.1))
                                            .clipShape(Circle())
                                            .onTapGesture { viewModel.selectedIcon = icon }
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                    .navigationTitle("Yeni Koleksiyon")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("İptal") { viewModel.showAddSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Oluştur") {
                                viewModel.createCollection()
                            }
                            .disabled(viewModel.newCollectionName.isEmpty)
                        }
                    }
                }
            }
            .onAppear {
                viewModel.loadCollections()
            }
        }
    }
}

// MARK: - Smart Collection Card
struct SmartCollectionCard: View {
    let collection: AppCollection
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: collection.icon)
                .font(.system(size: 30))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(Circle())
            
            VStack(spacing: 2) {
                Text(collection.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text("\(collection._count?.products ?? 0) Ürün")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 100, height: 130)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Collection Card
struct CollectionCard: View {
    let collection: AppCollection
    
    var totalValue: Double {
        collection.products?.reduce(0) { $0 + $1.currentPrice } ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Collage Cover
            GeometryReader { geo in
                let size = geo.size.width / 2
                let images = (collection.products ?? []).prefix(4).map { $0.imageUrl }
                
                ZStack {
                    if images.isEmpty {
                        Color.gray.opacity(0.1)
                        Image(systemName: collection.icon)
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    } else {
                        LazyVGrid(columns: [GridItem(.fixed(size), spacing: 0), GridItem(.fixed(size), spacing: 0)], spacing: 0) {
                            ForEach(0..<4) { index in
                                if index < images.count, let urlStr = images[index] {
                                    AsyncImage(url: URL(string: urlStr)) { img in
                                        img.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Color.gray.opacity(0.1)
                                    }
                                    .frame(width: size, height: size)
                                    .clipped()
                                } else {
                                    Color.gray.opacity(0.05)
                                        .frame(width: size, height: size)
                                }
                            }
                        }
                    }
                    
                    // Icon Badge
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: collection.icon)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .padding(6)
                        }
                    }
                }
            }
            .frame(height: 160)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(collection.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    if collection.isPublic {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack {
                    Text("\(collection._count?.products ?? 0) Ürün")
                    Spacer()
                    if totalValue > 0 {
                        Text(totalValue, format: .currency(code: "TRY"))
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
