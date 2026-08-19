import SwiftUI

struct TransitionAnimationView: View {
    @Binding var route: Route

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            Text("Animation")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.ink)
        }
        .task {
            try? await Task.sleep(for: .seconds(5))
            route = .home
        }
    }
}

#Preview {
    TransitionAnimationView(route: .constant(.animation))
}
