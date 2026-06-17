//
//  GitHubUser.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 08/06/26.
//

import Foundation
import Combine

struct GitHubUser : Codable,Identifiable,Hashable {
    let id : Int
    let login : String
    let avatarUrl : String
    let htmlUrl : String
    
    enum CodingKeys : String ,CodingKey {
        case id
        case login
        case avatarUrl = "avatar_url"
        case htmlUrl = "html_url"
    }
    
}
