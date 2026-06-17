//
//  GithubRepository.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 15/06/26.
//

import Foundation

protocol GithubRepository {
    
    func searchUsers(query : String ,page : Int) async throws -> [GitHubUser]
    
    func fetchRepos(for userName : String , page : Int) async throws -> [GitHubRepo]
}
