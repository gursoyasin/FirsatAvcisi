import SwiftUI
import Combine

// MARK: - Models
// ProductSummary moved to Core/Models/AlertLog.swift

// MARK: - ViewModel
class NotificationViewModel: ObservableObject {
    @Published var alerts: [AlertLog] = []
    @Published var isLoading = false
    
    func fetchNotifications() async {
        await MainActor.run { isLoading = true }
        do {
            let fetched = try await APIService.shared.fetchNotifications()
            await MainActor.run {
                self.alerts = fetched
                self.isLoading = false
            }
        } catch {
            print("Notification fetch error: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
}

// MARK: - View
struct NotificationListView: View {
    @StateObject private var viewModel = NotificationViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.alerts.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text(LocalizedStringKey("notification.empty"))
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.alerts) { alert in
                        HStack(alignment: .top, spacing: 12) {
                            // Product Image or Icon
                            if let url = alert.product?.imageUrl, let u = URL(string: url) {
                                AsyncImage(url: u) { i in i.resizable().aspectRatio(contentMode: .fill) } placeholder: { Color.gray }
                                    .frame(width: 50, height: 60)
                                    .cornerRadius(8)
                                    .clipped()
                            } else {
                                Image(systemName: alert.iconName)
                                    .font(.title2)
                                    .foregroundColor(alert.color)
                                    .frame(width: 50, height: 60)
                                    .background(alert.color.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(alert.message)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(3)
                                
                                Text(alert.timeAgo)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text(LocalizedStringKey("notification.title")))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text(LocalizedStringKey("common.close"))
                    }
                }
            }
            .task {
                await viewModel.fetchNotifications()
            }
            .refreshable {
                await viewModel.fetchNotifications()
            }
        }
    }
}
