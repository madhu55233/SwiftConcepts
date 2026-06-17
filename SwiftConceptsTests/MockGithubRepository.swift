//
//  MockGithubRepository.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 17/06/26.
//

import Foundation

/// Mock implementation of GithubRepository for unit testing
/// - Returns predefined data instead of making network calls
/// - Can simulate errors
/// - Tracks method calls for verification
final class MockGithubRepository: GithubRepository {
    
    // MARK: - Stubbed Data
    
    /// Users to return from searchUsers()
    var stubbedUsers: [GitHubUser] = []
    
    /// Repos to return from fetchRepos()
    var stubbedRepos: [GitHubRepo] = []
    
    /// Error to throw (if set, methods will throw this instead of returning data)
    var stubbedError: Error?
    
    /// Delay before returning (simulates network latency)
    var simulatedDelay: UInt64 = 0  // nanoseconds
    
    // MARK: - Call Tracking
    
    /// Number of times searchUsers was called
    private(set) var searchUsersCallCount = 0
    
    /// Arguments passed to last searchUsers call
    private(set) var lastSearchQuery: String?
    private(set) var lastSearchPage: Int?
    
    /// Number of times fetchRepos was called
    private(set) var fetchReposCallCount = 0
    
    /// Arguments passed to last fetchRepos call
    private(set) var lastFetchUsername: String?
    private(set) var lastFetchPage: Int?
    
    // MARK: - GithubRepository Protocol
    
    func searchUsers(query: String, page: Int) async throws -> [GitHubUser] {
        searchUsersCallCount += 1
        lastSearchQuery = query
        lastSearchPage = page
        
        // Simulate network delay if configured
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: simulatedDelay)
        }
        
        // Throw error if configured
        if let error = stubbedError {
            throw error
        }
        
        return stubbedUsers
    }
    
    func fetchRepos(for userName: String, page: Int) async throws -> [GitHubRepo] {
        fetchReposCallCount += 1
        lastFetchUsername = userName
        lastFetchPage = page
        
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: simulatedDelay)
        }
        
        if let error = stubbedError {
            throw error
        }
        
        return stubbedRepos
    }
    
    // MARK: - Test Helpers
    
    /// Reset all tracking state
    func reset() {
        searchUsersCallCount = 0
        lastSearchQuery = nil
        lastSearchPage = nil
        fetchReposCallCount = 0
        lastFetchUsername = nil
        lastFetchPage = nil
        stubbedError = nil
    }
    
    // MARK: - Factory Methods for Sample Data
    
    static func sampleUser(
        id: Int = 1,
        login: String = "octocat",
        avatarUrl: String = "https://example.com/avatar.png",
        htmlUrl: String = "https://github.com/octocat"
    ) -> GitHubUser {
        GitHubUser(
            id: id,
            login: login,
            avatarUrl: avatarUrl,
            htmlUrl: htmlUrl
        )
    }
    
    static func sampleRepo(
        id: Int = 1,
        name: String = "hello-world",
        fullName: String = "octocat/hello-world",
        description: String? = "My first repository",
        stargazersCount: Int = 100,
        language: String? = "Swift",
        htmlUrl: String = "https://github.com/octocat/hello-world",
        forksCount: Int = 10
    ) -> GitHubRepo {
        GitHubRepo(
            id: id,
            name: name,
            fullName: fullName,
            description: description,
            stargazersCount: stargazersCount,
            language: language,
            htmlUrl: htmlUrl,
            forksCount: forksCount
        )
    }
}
