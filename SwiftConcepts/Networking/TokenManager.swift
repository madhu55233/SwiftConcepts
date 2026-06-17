//
//  TokenManager.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 17/06/26.
//

import Foundation

/// Actor that manages GitHub API token
/// - Ensures thread-safe token access
/// - Handles token refresh without duplicate requests
/// - Stores token securely in Keychain (simplified to UserDefaults for demo)
actor TokenManager {
    
    // MARK: - State
    
    private var token: String?
    private var isRefreshing = false
    private var refreshContinuations: [CheckedContinuation<String, Error>] = []
    
    private let storageKey = "github_api_token"
    
    // MARK: - Singleton
    
    static let shared = TokenManager()
    
    private init() {
        // Load token from storage on init
        self.token = UserDefaults.standard.string(forKey: storageKey)
    }
    
    // MARK: - Public API
    
    /// Get a valid token, refreshing if necessary
    /// If multiple callers request a token while refresh is in progress,
    /// they all wait for the same refresh to complete (no duplicate requests)
    func validToken() async throws -> String {
        // If we have a token, return it
        if let token = token {
            return token
        }
        
        // If already refreshing, wait for that refresh to complete
        if isRefreshing {
            return try await withCheckedThrowingContinuation { continuation in
                refreshContinuations.append(continuation)
            }
        }
        
        // Start a new refresh
        return try await refreshToken()
    }
    
    /// Set a new token (e.g., after user logs in)
    func setToken(_ newToken: String) {
        self.token = newToken
        saveToken(newToken)
    }
    
    /// Clear the token (e.g., on logout)
    func clearToken() {
        self.token = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
    
    /// Check if user has a token
    var hasToken: Bool {
        token != nil
    }
    
    // MARK: - Private
    
    private func refreshToken() async throws -> String {
        isRefreshing = true
        defer {
            isRefreshing = false
            refreshContinuations.removeAll()
        }
        
        do {
            // Simulate token refresh (in real app, call your auth server)
            // For GitHub, you'd typically use OAuth flow
            let newToken = try await fetchNewToken()
            
            self.token = newToken
            saveToken(newToken)
            
            // Resume all waiting callers with the new token
            for continuation in refreshContinuations {
                continuation.resume(returning: newToken)
            }
            
            return newToken
            
        } catch {
            // Resume all waiting callers with the error
            for continuation in refreshContinuations {
                continuation.resume(throwing: error)
            }
            throw error
        }
    }
    
    private func fetchNewToken() async throws -> String {
        // In a real app, this would:
        // 1. Check if we have a refresh token
        // 2. Call the auth server to get a new access token
        // 3. Return the new token
        
        // For demo purposes, we simulate a network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // In production, throw an error if refresh fails
        // For demo, return a placeholder
        throw TokenError.noRefreshToken
    }
    
    private func saveToken(_ token: String) {
        // In production, use Keychain instead of UserDefaults
        // UserDefaults is NOT secure for sensitive data
        UserDefaults.standard.set(token, forKey: storageKey)
    }
}

// MARK: - Errors

enum TokenError: LocalizedError {
    case noRefreshToken
    case refreshFailed
    case invalidToken
    
    var errorDescription: String? {
        switch self {
        case .noRefreshToken:
            return "No refresh token available. Please log in again."
        case .refreshFailed:
            return "Failed to refresh authentication. Please log in again."
        case .invalidToken:
            return "Invalid authentication token."
        }
    }
}
