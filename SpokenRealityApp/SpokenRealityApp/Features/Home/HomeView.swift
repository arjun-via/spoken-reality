import SwiftUI

struct HomeView: View {
    @State private var projects: [Project] = []

    @State private var selectedProject: Project?
    @State private var showDevelopmentView = false

    let columns = [
        GridItem(.flexible(), spacing: Spacing.md),
        GridItem(.flexible(), spacing: Spacing.md)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                if projects.isEmpty {
                    emptyState
                } else {
                    projectGrid
                }
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: createNewProject) {
                        Image(systemName: "plus")
                            .foregroundColor(.accentPrimary)
                    }
                }
            }
            .navigationDestination(isPresented: $showDevelopmentView) {
                if selectedProject != nil {
                    DevelopmentView()
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var projectGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Spacing.md) {
                ForEach(projects) { project in
                    ProjectCard(project: project) {
                        selectProject(project)
                    }
                }
            }
            .padding(Spacing.md)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 64))
                .foregroundColor(.textSecondary)

            Text("No projects yet")
                .font(.title)
                .foregroundColor(.textPrimary)

            Text("Create your first app with voice")
                .font(.body)
                .foregroundColor(.textSecondary)

            Button(action: createNewProject) {
                Text("New Project")
                    .font(.bodyLarge)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.accentPrimary)
                    .cornerRadius(12)
            }
            .padding(.top, Spacing.md)
        }
    }

    private func selectProject(_ project: Project) {
        selectedProject = project
        showDevelopmentView = true
    }

    private func createNewProject() {
        let newProject = Project(name: "New Project \(projects.count + 1)")
        projects.insert(newProject, at: 0)
        selectProject(newProject)
    }
}

#Preview {
    HomeView()
}
