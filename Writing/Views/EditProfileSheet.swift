import SwiftUI
import PhotosUI

struct EditProfileSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var imageData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Group {
                                if let imageData, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Circle()
                                        .fill(Theme.card)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 28))
                                                .foregroundStyle(Theme.ink)
                                        )
                                }
                            }
                            .frame(width: 84, height: 84)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Theme.ink, lineWidth: 2))
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Name") {
                    TextField("Your name", text: $name)
                }

                Section("Bio") {
                    TextField("A short bio", text: $bio, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.profileName = name
                        store.profileBio = bio
                        store.profileImageData = imageData
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            name = store.profileName
            bio = store.profileBio
            imageData = store.profileImageData
        }
        .task(id: photoItem) {
            guard let photoItem, let data = try? await photoItem.loadTransferable(type: Data.self) else { return }
            imageData = data
        }
    }
}

#Preview {
    EditProfileSheet()
        .environmentObject(AppStore())
}
