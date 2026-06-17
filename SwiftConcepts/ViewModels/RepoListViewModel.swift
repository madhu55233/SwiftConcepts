//
//  RepoListViewModel.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 17/06/26.
//

import Foundation
import Combine

@MainActor
final class RepoListViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var repos: [GitHubRepo] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let repository: GithubRepository
    private let username: String
    private var currentPage = 1
    private var hasMorePages = true

    // MARK: - Init

    init(repository: GithubRepository, username: String) {
        self.repository = repository
        self.username = username
    }

    // MARK: - Load Repos

    func loadInitialRepos() async {
        currentPage = 1
        hasMorePages = true
        repos = []
        await loadPage()
    }

    func loadMoreIfNeeded(currentRepo: GitHubRepo) {
        guard let index = repos.firstIndex(where: { $0.id == currentRepo.id }) else { return }

        let thresholdIndex = repos.count - 3
        if index >= thresholdIndex {
            loadNextPage()
        }
    }

    func loadNextPage() {
        guard !isLoading, hasMorePages else { return }

        Task {
            await loadPage()
        }
    }

    private func loadPage() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let newRepos = try await repository.fetchRepos(
                for: username,
                page: currentPage
            )

            // Append new repos
            let existingIds = Set(repos.map { $0.id })
            let uniqueNewRepos = newRepos.filter { !existingIds.contains($0.id) }
            repos.append(contentsOf: uniqueNewRepos)

            // Update pagination
            hasMorePages = newRepos.count >= 20
            currentPage += 1

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
