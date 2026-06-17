//
//  RepoListView.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 17/06/26.
//

import SwiftUI

struct RepoListView: View {
    
    @StateObject private var viewModel: RepoListViewModel
    @EnvironmentObject private var favoritesViewModel: FavoritesViewModel
    
    let username: String
    let avatarUrl: String
    
    init(repository: GithubRepository, username: String, avatarUrl: String) {
        self.username = username
        self.avatarUrl = avatarUrl
        _viewModel = StateObject(wrappedValue: RepoListViewModel(
            repository: repository,
            username: username
        ))
    }
    
    var body: some View {
        content
            .navigationTitle(username)
            .task {
                // Load repos when view appears
                await viewModel.loadInitialRepos()
            }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.repos.isEmpty {
            ProgressView("Loading repositories...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        } else if viewModel.repos.isEmpty {
            emptyStateView
        } else {
            repoList
        }
    }
    
    // MARK: - Repo List
    
    private var repoList: some View {
        List {
            // Header with user info
            userHeader
                .listRowSeparator(.hidden)
            
            // Repos
            ForEach(viewModel.repos) { repo in
                RepoRowView(
                    repo: repo,
                    isFavorite: favoritesViewModel.isFavorite(repo),
                    onFavoriteToggle: {
                        favoritesViewModel.toggleFavorite(repo)
                    }
                )
                .onAppear {
                    viewModel.loadMoreIfNeeded(currentRepo: repo)
                }
            }
            
            // Pagination loading
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
    
    // MARK: - Header
    
    private var userHeader: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: avatarUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(username)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(viewModel.repos.count) repositories")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Empty States
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Repositories",
            systemImage: "folder",
            description: Text("\(username) doesn't have any public repositories.")
        )
    }
    
    private func errorView(message: String) -> some View {
        ContentUnavailableView(
            "Couldn't Load Repositories",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
    }
}
