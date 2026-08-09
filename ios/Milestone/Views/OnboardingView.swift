import SwiftUI

public struct OnboardingView: View {
    public let onComplete: () -> Void
    @Environment(UserStore.self) private var userStore
    @Environment(\.theme) private var theme

    @State private var step: Int = 1
    @State private var nameInput: String = ""
    @FocusState private var isNameFocused: Bool

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack {
                if step == 1 {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()

                        Text("MILESTONE")
                            .font(.system(size: 11, weight: .heavy))
                            .tracking(4)
                            .foregroundStyle(theme.accent)
                            .padding(.bottom, 24)

                        Text("One mission.\nThat's it.")
                            .font(.system(size: 42, weight: .bold))
                            .lineSpacing(0)
                            .tracking(-1)
                            .foregroundStyle(theme.textPrimary)
                            .padding(.bottom, 24)

                        Text("Focus on what matters. Ignore the noise. Conquering your goals begins with a single step.")
                            .font(.system(size: 17, weight: .regular))
                            .lineSpacing(4)
                            .foregroundStyle(theme.textTertiary)

                        Spacer()

                        Button {
                            HapticsManager.shared.impact(.light)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                step = 2
                            }
                        } label: {
                            Text("CONTINUE")
                                .font(.system(size: 13, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(theme.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(theme.accent)
                                )
                        }
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 32)
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()

                        Text("SETUP")
                            .font(.system(size: 11, weight: .heavy))
                            .tracking(4)
                            .foregroundStyle(theme.accent)
                            .padding(.bottom, 32)

                        Text("WHAT SHOULD WE CALL YOU?")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(2)
                            .foregroundStyle(theme.textSecondary)
                            .padding(.bottom, 12)

                        TextField("Enter your name", text: $nameInput)
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(theme.textPrimary)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.surface)
                            )
                            .focused($isNameFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                finishOnboarding()
                            }

                        Spacer()

                        Button {
                            finishOnboarding()
                        } label: {
                            Text("START MISSION")
                                .font(.system(size: 13, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(theme.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(theme.accent)
                                )
                        }
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 32)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                    .onAppear {
                        isNameFocused = true
                    }
                }
            }
        }
    }

    private func finishOnboarding() {
        HapticsManager.shared.notification(.success)
        let trimmed = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        userStore.userName = trimmed.isEmpty ? "Commander" : trimmed
        userStore.hasSeenOnboarding = true
        onComplete()
    }
}
