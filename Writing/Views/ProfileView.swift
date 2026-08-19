import SwiftUI

enum ProfileTab {
    case publish
    case drafts
}

struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @Binding var route: Route

    @State private var selectedTab: ProfileTab = .publish
    @State private var showEditSheet = false

    private var visibleEntries: [WritingEntry] {
        selectedTab == .publish ? store.publishedEntries : store.draftEntries
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                header

                avatar

                VStack(spacing: 4) {
                    Text(store.profileName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text(store.profileBio)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                tabSwitcher

                entryList
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .sheet(isPresented: $showEditSheet) {
            EditProfileSheet()
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack {
            RoundBackButton { route = .home }
            Spacer()
            Text("My Profile")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Color.clear.frame(width: 34, height: 34)
        }
        .padding(.horizontal, 20)
    }

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let data = store.profileImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle()
                        .fill(Theme.card)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(Theme.ink)
                        )
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(Circle())
            .overlay(Circle().stroke(Theme.ink, lineWidth: 3.5))

            Button {
                showEditSheet = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.card)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Theme.ink))
                    .overlay(Circle().stroke(Theme.background, lineWidth: 2))
            }
        }
    }

    private var tabSwitcher: some View {
        HStack(spacing: 8) {
            tabButton(title: "Publish (\(store.publishedEntries.count))", tab: .publish)
            tabButton(title: "Drafts (\(store.draftEntries.count))", tab: .drafts)
        }
    }

    private func tabButton(title: String, tab: ProfileTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.card : Theme.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.ink : Theme.card)
                        .overlay(Capsule().stroke(Theme.ink, lineWidth: 1.5))
                )
        }
    }

    private var entryList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if visibleEntries.isEmpty {
                    Text(selectedTab == .publish ? "Nothing published yet." : "No drafts yet.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkMuted)
                        .padding(.top, 40)
                } else {
                    ForEach(visibleEntries) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.body)
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.ink)
                                .lineLimit(3)
                            Text(entry.dateLabel)
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.inkMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.card))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink.opacity(0.4), lineWidth: 1.5))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
}

#Preview {
    ProfileView(route: .constant(.profile))
        .environmentObject(AppStore())
}
