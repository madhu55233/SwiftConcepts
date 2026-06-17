//
//  CachedGitHubRepository.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 16/06/26.
//

import Foundation

final class CachedGithubRepository: GithubRepository {
    
    private let real: GithubRepository
    private var userCache: [String: [GitHubUser]] = [:]
    private var repoCache: [String: [GitHubRepo]] = [:]
    
    init(real: GithubRepository) {
        self.real = real
    }
    
    func searchUsers(query: String, page: Int) async throws -> [GitHubUser] {
        let key = "\(query.lowercased())_page\(page)"
        
        // Cache hit
        if let cached = userCache[key] {
            print("✅ Cache hit: \(key)")
            return cached
        }
        
        // Cache miss — fetch from network
        print("🌐 Network fetch: \(key)")
        let users = try await real.searchUsers(query: query, page: page)
        userCache[key] = users
        return users
    }
    
    func fetchRepos(for userName: String, page: Int) async throws -> [GitHubRepo] {
        let key = "\(userName.lowercased())_page\(page)"
        
        if let cached = repoCache[key] {
            print("✅ Cache hit: \(key)")
            return cached
        }
        
        print("🌐 Network fetch: \(key)")
        let repos = try await real.fetchRepos(for: userName, page: page)
        repoCache[key] = repos
        return repos
    }
}
