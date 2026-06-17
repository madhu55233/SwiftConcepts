//
//  PaginationController.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 17/06/26.
//

import Foundation

import Foundation

final class PaginationController {

    // MARK: - State

    private(set) var currentPage: Int = 1
    private(set) var isLoading: Bool = false
    private(set) var hasMorePages: Bool = true

    private let pageSize: Int

    // MARK: - Closure Callbacks

    /// Called when a new page should be loaded
    /// The Int parameter is the page number to load
    var onLoadPage: ((Int) async throws -> Void)?

    /// Called when an error occurs during loading
    var onError: ((Error) -> Void)?

    /// Called when loading state changes (for showing/hiding spinner)
    var onLoadingStateChanged: ((Bool) -> Void)?

    // MARK: - Init

    init(pageSize: Int = 20) {
        self.pageSize = pageSize
    }

    // MARK: - Public API

    /// Reset to page 1 — call this when starting a new search
    func reset() {
        currentPage = 1
        hasMorePages = true
        isLoading = false
    }

    /// Call this when user scrolls near the bottom of the list
    func loadNextPageIfNeeded() {
        guard !isLoading, hasMorePages else { return }

        Task { [weak self] in
            await self?.loadPage()
        }
    }

    /// Call this after receiving results to update pagination state
    /// - Parameter itemsReceived: number of items returned from the API
    func didReceiveItems(count: Int) {
        // If we got fewer items than page size, we've reached the end
        if count < pageSize {
            hasMorePages = false
        }
    }

    // MARK: - Private

    private func loadPage() async {
        isLoading = true
        onLoadingStateChanged?(true)        // ← closure callback

        defer {
            isLoading = false
            onLoadingStateChanged?(false)   // ← closure callback
        }

        do {
            try await onLoadPage?(currentPage)   // ← closure callback
            currentPage += 1
        } catch {
            onError?(error)                      // ← closure callback
        }
    }
}
