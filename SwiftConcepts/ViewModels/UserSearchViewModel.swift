//
//  UserSearchViewModel.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 17/06/26.
//

import Foundation
import Combine

@MainActor
final class UserSearchViewModel: ObservableObject {
    
    // MARK: - Published State (View observes these)
    @Published var searchText: String = ""
    @Published private(set) var users: [GitHubUser] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var hasSearched: Bool = false
    
    // MARK: - Dependencies
    
    private let repository: GithubRepository
    private var cancellables = Set<AnyCancellable>()
    private var currentPage = 1
    private var hasMorePages = true
    private var currentQuery = ""
    
    // MARK: - Init
    
    init(repository: GithubRepository) {
        self.repository = repository
        setupSearchDebounce()
    }
    
    // MARK: - Combine: Debounced Search
    
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .sink { [weak self] query in
                guard let self else { return }
                
                if query.isEmpty {
                    self.users = []
                    self.hasSearched = false
                    self.errorMessage = nil
                } else {
                    Task {
                        await self.searchUsers(query: query)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Search
    
    private func searchUsers(query: String) async {
        // New search — reset pagination
        currentQuery = query
        currentPage = 1
        hasMorePages = true
        users = []
        
        await loadPage()
    }
    
    func loadMoreIfNeeded(currentUser: GitHubUser) {
        guard let index = users.firstIndex(where: { $0.id == currentUser.id }) else { return }
        
        let thresholdIndex = users.count - 3
        if index >= thresholdIndex {
            loadNextPage()
        }
    }
    
    func loadNextPage() {
        guard !isLoading, hasMorePages, !currentQuery.isEmpty else { return }
        
        Task {
            await loadPage()
        }
    }
    
    private func loadPage() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let newUsers = try await repository.searchUsers(
                query: currentQuery,
                page: currentPage
            )
            
            // Append new users (avoid duplicates)
            let existingIds = Set(users.map { $0.id })
            let uniqueNewUsers = newUsers.filter { !existingIds.contains($0.id) }
            users.append(contentsOf: uniqueNewUsers)
            
            // Update pagination state
            hasMorePages = newUsers.count >= 20
            currentPage += 1
            hasSearched = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Clear
    
    func clearSearch() {
        searchText = ""
        users = []
        hasSearched = false
        errorMessage = nil
        currentQuery = ""
        currentPage = 1
        hasMorePages = true
    }
}
