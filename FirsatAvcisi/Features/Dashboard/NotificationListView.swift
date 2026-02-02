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
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.alerts.isEmpty && !viewModel.isLoading {
                        VStack(spacing: 20) {
                            Image(systemName: "bell.slash.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary.opacity(0.3))
                                .padding(.top, 60)
                            Text(LocalizedStringKey("notification.empty"))
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ForEach(viewModel.alerts) { alert in
                            HStack(alignment: .top, spacing: 16) {
                                // Premium Icon/Image Container
                                ZStack {
                                    if let url = alert.product?.imageUrl, let u = URL(string: url) {
                                        AsyncImage(url: u) { i in
                                            i.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color(uiColor: .secondarySystemBackground)
                                        }
                                        .frame(width: 56, height: 56)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    } else {
                                        Circle()
                                            .fill(alert.color.opacity(0.15))
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: alert.iconName)
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(alert.color)
                                    }
                                    
                                    // New Dot
                                    if alert.timeAgo.contains("saniye") || alert.timeAgo.contains("dakika") {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 10, height: 10)
                                            .offset(x: 26, y: -26)
                                            .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2).offset(x: 26, y: -26))
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(alert.message)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)
                                        .lineLimit(3)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Text(alert.timeAgo)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.top, 10)
            }
            .background(Color(uiColor: .systemGroupedBackground))
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
