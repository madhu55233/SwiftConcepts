//
//  Repository.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 08/06/26.
//

import Foundation

struct GitHubRepo : Codable , Identifiable , Hashable {
    let id: Int
     let name: String                // repo name e.g. "swift"
     let fullName: String            // "apple/swift"
     let description: String?        // optional — some repos have no description
     let stargazersCount: Int        // ⭐ count
     let language: String?           // optional — some repos have no language set
     let htmlUrl: String             // link to repo on GitHub
     let forksCount: Int
    
    enum CodingKeys: String, CodingKey {
            case id, name, description, language
            case fullName       = "full_name"
            case stargazersCount = "stargazers_count"
            case htmlUrl        = "html_url"
            case forksCount     = "forks_count"
        }
}
