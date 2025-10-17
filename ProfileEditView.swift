import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    Text("Profile editor coming soon")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Profile")
        }
    }
}

#Preview {
    ProfileEditView()
}
