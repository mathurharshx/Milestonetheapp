import SwiftUI

public struct ProfileSheet: View {
    @Environment(UserStore.self) private var userStore
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                // Header Row with back chevron
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(theme.textPrimary)
                    }

                    Spacer()

                    Text("Profile")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)

                    Spacer()

                    // Invisible placeholder for centered title alignment
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .opacity(0)
                }
                .padding(.top, 16)

                // Content
                VStack(alignment: .leading, spacing: 12) {
                    Text("YOUR NAME")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(theme.textSecondary)

                    TextField("Enter your name", text: $name)
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(theme.textPrimary)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.surface)
                        )
                        .onChange(of: name) { _, newValue in
                            userStore.userName = newValue
                        }
                }
                .padding(.top, 24)

                Spacer()
            }
            .padding(.horizontal, 24)
            .background(theme.background.ignoresSafeArea())
            .onAppear {
                name = userStore.userName
            }
        }
    }
}
