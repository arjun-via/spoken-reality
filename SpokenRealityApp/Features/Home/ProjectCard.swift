import SwiftUI

struct ProjectCard: View {
    let project: Project
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Thumbnail
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.bgTertiary)
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        Image(systemName: "app.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.textTertiary)
                    )

                // Project name
                Text(project.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                // Last edited
                Text(relativeTime(from: project.lastEdited))
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(Spacing.sm)
            .background(Color.bgSecondary)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ProjectCard(project: Project(name: "Test Project")) {}
        .padding()
        .background(Color.bgPrimary)
}
