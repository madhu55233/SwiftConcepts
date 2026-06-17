//
//  FavouriteRepository.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 08/06/26.
//

import Foundation

struct FavouriteRepo : Codable , Identifiable , Hashable {
    let id : Int
    let name : String
    let fullName : String
    let stargazersCount : Int
    
    init(from repo: GitHubRepo)  {
        self.id = repo.id
        self.name = repo.name
        self.fullName = repo.fullName
        self.stargazersCount = repo.stargazersCount
    }
}
