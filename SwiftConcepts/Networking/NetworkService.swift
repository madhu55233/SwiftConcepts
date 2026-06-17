//
//  NetworkService.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 09/06/26.
//

import Foundation

// 'final' means no subclassing — this class is the definitive implementation

final class NetworkService {
    
    static let shared = NetworkService()
    private let tokenManager = TokenManager.shared
    
    private init() {}
    
    // MARK: - Fetch without auth (public GitHub API)
    
    func fetch<T: Decodable>(
            _ endpoint: APIEndpoint,
            token: String? = nil
    ) async throws -> T {
        let request = endpoint.urlRequest(token: token)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break   // success — continue to decoding
        case 401:
            throw NetworkError.httpError(statusCode: 401)  // Unauthorized
        case 403:
            throw NetworkError.httpError(statusCode: 403)  // Rate limited
        case 404:
            throw NetworkError.httpError(statusCode: 404)  // Not found
        default:
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    // MARK: - Fetch with automatic auth from TokenManager
    
    /// Fetches data with automatic token management
    /// - Uses TokenManager to get/refresh token
    /// - Retries once on 401 (token expired)
    func fetchWithAuth<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        // Try to get a valid token (may trigger refresh)
        let token: String?
        do {
            token = try await tokenManager.validToken()
        } catch {
            // No token available — proceed without auth (lower rate limit)
            token = nil
        }
        
        do {
            return try await fetch(endpoint, token: token)
        } catch NetworkError.httpError(statusCode: 401) {
            // Token might be expired — clear and retry once
            await tokenManager.clearToken()
            
            // Try again without token
            return try await fetch(endpoint, token: nil)
        }
    }
}
