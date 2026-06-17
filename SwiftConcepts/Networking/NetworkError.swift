//
//  NetworkError.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 09/06/26.
//

import Foundation

enum NetworkError : LocalizedError {
    case invalidResponse
    case httpError(statusCode : Int)
    case decodingError(Error)
    case noInternet
    
    var errorDescription: String? {
        switch self {
            
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .httpError(statusCode: let statusCode):
            return "Server returned error code \(statusCode)."
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .noInternet:
            return "No internet connection. Showing cached results."
        }
    }
}
