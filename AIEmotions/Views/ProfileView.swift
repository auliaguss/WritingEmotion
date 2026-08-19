//
//  ProfileView.swift
//  AIEmotions
//
//  Profile now also hosts Drafts/Published — there's no separate tab
//  bar anymore, so this is the only place those lists live, switched
//  via a segmented "Publish (n) / Drafts (n)" toggle.
//
//  Visual styling (Theme + hardCard) ported from the "Writing" branch.
//

import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
import SwiftData
#endif

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var user: User

    @State private var photoItem: PhotosPickerItem?
    @State private var draftBio: String = ""
    @State private var isEditing = false
    @State private var selectedMode: PostListMode = .published
    @State private var selectedDraft: Post?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        avatar
                    }
                    .onChange(of: photoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                user.updateProfile(newBio: user.profileText, newPictureData: data)
                            }
                        }
                    }

                    VStack(spacing: 10) {
                        if isEditing {
                            TextField("Say something about your writing…", text: $draftBio, axis: .vertical)
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.ink)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.card))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.ink, lineWidth: 1.5))

                            Button {
                                user.updateProfile(newBio: draftBio, newPictureData: user.profilePictureData)
                                isEditing = false
                            } label: {
                                Text("Save")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                            }
                            .hardCard(cornerRadius: 16, shadowOffset: 3)
                        } else {
                            Text(user.profileText.isEmpty ? "Lorem ipsum" : user.profileText)
                                .font(.system(size: 13))
                                .foregroundStyle(user.profileText.isEmpty ? Theme.inkMuted : Theme.ink)
                                .multilineTextAlignment(.center)

                            Button {
                                draftBio = user.profileText
                                isEditing = true
                            } label: {
                                Text("Edit bio")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                            }
                            .hardCard(cornerRadius: 16, shadowOffset: 3)
                        }
                    }
                    .padding(.horizontal, 32)

                    StyleSummaryCard(user: user)

                    modeToggle

                    PostListContent(user: user, mode: selectedMode) { draft in
                        selectedDraft = draft
                    }
                    .frame(minHeight: 200)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $selectedDraft) { draft in
            WritingView(user: user, draft: draft)
        }
    }

    private var header: some View {
        HStack {
            RoundBackButton { dismiss() }
            Spacer()
            Text("My Profile")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Color.clear.frame(width: 34, height: 34)
        }
    }

    private var avatar: some View {
        Group {
            if let data = user.profilePictureData, let uiImage = UIImage(data: data) {
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
    }

    private var modeToggle: some View {
        HStack(spacing: 8) {
            toggleButton("Publish (\(user.loadPublished().count))", mode: .published)
            toggleButton("Drafts (\(user.loadDrafts().count))", mode: .drafts)
        }
    }

    private func toggleButton(_ title: String, mode: PostListMode) -> some View {
        let isSelected = selectedMode == mode
        return Button {
            selectedMode = mode
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
}

#Preview {
    let user = User(profileText: "Writing my way through feelings.", emotionProfile: ["nostalgia": 4, "hope": 2, "unease": 1])
    return NavigationStack {
        ProfileView(user: user)
    }
    .modelContainer(for: [User.self, Post.self], inMemory: true)
}
