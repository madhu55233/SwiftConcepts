//
//  GithubRepositoryImp.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 15/06/26.
//

import Foundation

final class GitHubRepositoryImpl : GithubRepository {
    
    private let network : NetworkService
    
    init(network: NetworkService = .shared) {
        self.network = network
    }
    
    func searchUsers(query: String, page: Int) async throws -> [GitHubUser] {
        let response : UserSearchResponse = try await network.fetch(.searchUser(query: query, page: page))
        return response.items
    }
    
    func fetchRepos(for userName: String, page: Int) async throws -> [GitHubRepo] {
        return try await network.fetch(.userRepos(username: userName, page: page))
    }   
    
}
