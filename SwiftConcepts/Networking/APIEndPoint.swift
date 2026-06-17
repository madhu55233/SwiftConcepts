//
//  APIEndPoint.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 08/06/26.
//

import Foundation

enum APIEndpoint {
    case searchUser(query : String , page : Int)
    case userRepos(username : String , page : Int)
    
    private static let base = "https://api.github.com"
    private static let perPage = 20
    
    var url : URL {
        switch self {
            
        case .searchUser(query: let query, page: let page):
            var components = URLComponents(string: "\(Self.base)/search/users")!
                        components.queryItems = [
                            URLQueryItem(name: "q",        value: query),
                            URLQueryItem(name: "per_page", value: "\(Self.perPage)"),
                            URLQueryItem(name: "page",     value: "\(page)")
                        ]
                        return components.url!

        case .userRepos(username: let username, page: let page):
            var components = URLComponents(string: "\(Self.base)/users/\(username)/repos")!
                        components.queryItems = [
                            URLQueryItem(name: "per_page", value: "\(Self.perPage)"),
                            URLQueryItem(name: "page",     value: "\(page)"),
                            URLQueryItem(name: "sort",     value: "stars")
                        ]
                        return components.url!
        }
    }
    
    func urlRequest(token: String?) -> URLRequest {
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

            // Add auth token if available (increases rate limit from 60 to 5000 req/hour)
            if let token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            return request
        }
}
