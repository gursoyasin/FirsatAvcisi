import SwiftUI
import Combine

class UIState: ObservableObject {
    @Published var isTabBarHidden: Bool = false
}
