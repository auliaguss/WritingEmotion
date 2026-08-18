//
//  ProfileView.swift
//  AIEmotions
//
//  Profile now also hosts Drafts/Published — there's no separate tab
//  bar anymore, so this is the only place those lists live, switched
//  via a segmented "Publish (n) / Drafts (n)" toggle.
//

import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
import SwiftData
#endif

struct ProfileView: View {
    @Bindable var user: User

    @State private var photoItem: PhotosPickerItem?
    @State private var draftBio: String = ""
    @State private var isEditing = false
    @State private var selectedMode: PostListMode = .published

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
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

                if isEditing {
                    TextField("Say something about your writing…", text: $draftBio, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                    Button("Save") {
                        user.updateProfile(newBio: draftBio, newPictureData: user.profilePictureData)
                        isEditing = false
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Text(user.profileText.isEmpty ? "Lorem ipsum" : user.profileText)
                        .foregroundStyle(user.profileText.isEmpty ? .secondary : .primary)
                        .multilineTextAlignment(.center)
                    Button("Edit bio") {
                        draftBio = user.profileText
                        isEditing = true
                    }
                    .buttonStyle(.bordered)
                }

                if !user.emotionProfile.isEmpty {
                    emotionBreakdown
                }

                modeToggle

                PostListContent(user: user, mode: selectedMode)
                    .frame(minHeight: 200)
            }
            .padding()
        }
        .navigationTitle("My Profile")
    }

    private var avatar: some View {
        Group {
            if let data = user.profilePictureData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(Circle())
    }

    private var modeToggle: some View {
        HStack(spacing: 12) {
            toggleButton("Publish (\(user.loadPublished().count))", mode: .published)
            toggleButton("Drafts (\(user.loadDrafts().count))", mode: .drafts)
        }
    }

    private func toggleButton(_ title: String, mode: PostListMode) -> some View {
        Button {
            selectedMode = mode
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .tint(selectedMode == mode ? .brown : Color(.systemGray4))
        .foregroundStyle(selectedMode == mode ? .white : .primary)
    }

    private var emotionBreakdown: some View {
        let total = max(user.emotionProfile.values.reduce(0, +), 1)
        let sorted = user.emotionProfile.sorted { $0.value > $1.value }

        return VStack(alignment: .leading, spacing: 10) {
            Text("Your emotional palette")
                .font(.headline)

            ForEach(sorted, id: \.key) { emotion, count in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(emotion.capitalized)
                            .font(.subheadline)
                        Spacer()
                        Text("\(count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor.opacity(0.25))
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.accentColor)
                                    .frame(width: geo.size.width * CGFloat(count) / CGFloat(total))
                            }
                    }
                    .frame(height: 8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let user = User(profileText: "Writing my way through feelings.", emotionProfile: ["nostalgia": 4, "hope": 2, "unease": 1])
    return NavigationStack {
        ProfileView(user: user)
    }
    .modelContainer(for: [User.self, Post.self], inMemory: true)
}
