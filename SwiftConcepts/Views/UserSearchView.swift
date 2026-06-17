//
//  UserSearchView.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 17/06/26.
//

import SwiftUI

struct UserSearchView: View {
    
    @StateObject private var viewModel: UserSearchViewModel
    @EnvironmentObject private var favoritesViewModel: FavoritesViewModel
    
    private let repository: GithubRepository
    
    // Dependency injection via init
    init(repository: GithubRepository) {
        self.repository = repository
        _viewModel = StateObject(wrappedValue: UserSearchViewModel(repository: repository))
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("GitHub Search")
                .searchable(
                    text: $viewModel.searchText,
                    prompt: "Search users..."
                )
        }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.users.isEmpty {
            // Initial loading state
            ProgressView("Searching...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
            // Error state
            errorView(message: error)
        } else if viewModel.users.isEmpty && viewModel.hasSearched {
            // Empty state after search
            emptyStateView
        } else if viewModel.users.isEmpty {
            // Initial state — no search yet
            welcomeView
        } else {
            // Results list
            userList
        }
    }
    
    // MARK: - User List
    
    private var userList: some View {
        List {
            ForEach(viewModel.users) { user in
                NavigationLink(destination: repoListDestination(for: user)) {
                    UserRowView(user: user)
                }
                .onAppear {
                    // Trigger pagination when row appears
                    viewModel.loadMoreIfNeeded(currentUser: user)
                }
            }
            
            // Loading indicator at bottom during pagination
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Navigation Destination
    
    private func repoListDestination(for user: GitHubUser) -> some View {
        RepoListView(
            repository: repository,
            username: user.login,
            avatarUrl: user.avatarUrl
        )
    }
    
    // MARK: - Empty States
    
    private var welcomeView: some View {
        ContentUnavailableView(
            "Search GitHub Users",
            systemImage: "magnifyingglass",
            description: Text("Enter a username to find GitHub users and explore their repositories.")
        )
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Users Found",
            systemImage: "person.slash",
            description: Text("No users match '\(viewModel.searchText)'. Try a different search.")
        )
    }
    
    private func errorView(message: String) -> some View {
        ContentUnavailableView(
            "Something Went Wrong",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
    }
}
