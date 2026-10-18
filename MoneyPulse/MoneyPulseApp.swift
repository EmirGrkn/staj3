import SwiftUI

@main
struct MoneyPulseApp: App {
    /// The single source of truth for the whole app.
    @StateObject private var viewModel = FinanceViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
                .preferredColorScheme(.dark)
        }
    }
}
