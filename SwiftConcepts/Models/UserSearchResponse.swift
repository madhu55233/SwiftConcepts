//
//  UserSearchResponse.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 08/06/26.
//

import Foundation

struct UserSearchResponse : Codable {
    let totalCount : Int
    let items : [GitHubUser]
    
    enum CodingKeys : String, CodingKey {
        case totalCount = "total_count"
        case items
    }
}
