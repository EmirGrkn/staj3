import SwiftUI

/// Shows onboarding on first launch, then the main tab bar.
struct RootView: View {
    @EnvironmentObject private var viewModel: FinanceViewModel

    var body: some View {
        Group {
            if viewModel.hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.hasCompletedOnboarding)
    }
}

enum AppTab: Hashable {
    case pulse, add, goals, profile
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .pulse
    @State private var addMode: AddView.Mode = .expense

    var body: some View {
        TabView(selection: $selectedTab) {
            PulseView(onAddExpense: {
                addMode = .expense
                selectedTab = .add
            })
            .tabItem { Label("Pulse", systemImage: "waveform.path.ecg") }
            .tag(AppTab.pulse)

            AddView(mode: $addMode)
                .tabItem { Label("Add", systemImage: "plus.circle.fill") }
                .tag(AppTab.add)

            GoalsView()
                .tabItem { Label("Goals", systemImage: "target") }
                .tag(AppTab.goals)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(AppTab.profile)
        }
        .tint(Color.pulseGreen)
    }
}

#Preview {
    let viewModel = FinanceViewModel(storage: StorageService(defaults: UserDefaults(suiteName: "preview")!))
    viewModel.startWithDemoData()
    return RootView()
        .environmentObject(viewModel)
        .preferredColorScheme(.dark)
}
