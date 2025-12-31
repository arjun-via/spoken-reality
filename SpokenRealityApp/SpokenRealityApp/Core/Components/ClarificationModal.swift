import SwiftUI

// MARK: - Clarification Modal

struct ClarificationModal: View {
    let question: String
    let options: [String]?
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var customResponse: String = ""
    @State private var showCustomInput: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                VStack(spacing: Spacing.xl) {
                    // Question
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.accentPrimary)

                        Text(question)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Spacing.xl)

                    // Options
                    if let options = options, !options.isEmpty {
                        VStack(spacing: Spacing.sm) {
                            ForEach(options, id: \.self) { option in
                                Button(action: {
                                    handleSelection(option)
                                }) {
                                    Text(option)
                                        .font(.body)
                                        .foregroundColor(.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(Spacing.md)
                                        .background(Color.bgSecondary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }

                    // Custom response option
                    if !showCustomInput {
                        Button(action: {
                            showCustomInput = true
                        }) {
                            HStack {
                                Image(systemName: "text.bubble")
                                Text("Other (type response)")
                            }
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.md)
                            .background(Color.bgTertiary)
                            .cornerRadius(8)
                        }
                    } else {
                        // Custom input field
                        VStack(spacing: Spacing.sm) {
                            TextField("Type your response...", text: $customResponse)
                                .foregroundColor(.textPrimary)
                                .padding(Spacing.md)
                                .background(Color.bgSecondary)
                                .cornerRadius(8)
                                .autocapitalization(.sentences)

                            Button(action: {
                                handleSelection(customResponse)
                            }) {
                                Text("Submit")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(Spacing.md)
                                    .background(customResponse.isEmpty ? Color.textTertiary : Color.accentPrimary)
                                    .cornerRadius(8)
                            }
                            .disabled(customResponse.isEmpty)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, Spacing.xl)
            }
            .navigationTitle("Quick Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func handleSelection(_ response: String) {
        onSelect(response)
        dismiss()
    }
}

#Preview {
    ClarificationModal(
        question: "What type of authentication do you want?",
        options: ["Email/Password", "Google OAuth", "GitHub OAuth"],
        onSelect: { response in
            print("Selected: \(response)")
        }
    )
}
