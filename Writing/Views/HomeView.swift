import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: AppStore
    @Binding var route: Route

    var body: some View {
        ZStack(alignment: .top) {
            Theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                actionButton(
                    title: "Write",
                    icon: "pencil",
                    caption: "Start writing and see where it takes you!"
                ) {
                    route = .writing
                }

                if store.hasEntries {
                    actionButton(
                        title: "Read",
                        icon: "book.fill",
                        caption: "Discover a piece written by someone else!"
                    ) {}
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 90)

            HStack {
                Spacer()
                Button {
                    route = .profile
                } label: {
                    Image(systemName: "person.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(Theme.card))
                        .overlay(Circle().stroke(Theme.ink, lineWidth: 2.5))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    private func actionButton(
        title: String,
        icon: String,
        caption: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .center, spacing: 8) {
            Button(action: action) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                    Text(title)
                        .fontWeight(.bold)
                }
                .font(.system(size: 20))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
            }
            .hardCard()
            .padding(.trailing, 6)
            .padding(.bottom, 6)

            Text(caption)
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    HomeView(route: .constant(.home))
        .environmentObject(AppStore())
}
