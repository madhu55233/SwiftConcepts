//
//  FavoritesViewModelTests.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 17/06/26.
//

import XCTest
@testable import SwiftConcepts

/// Unit tests for FavoritesViewModel
/// Tests add, remove, toggle, and persistence of favorites
@MainActor
final class FavoritesViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: FavoritesViewModel!
    private let testUserDefaultsKey = "favorite_repos_test"
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        // Clear any existing test data
        UserDefaults.standard.removeObject(forKey: "favorite_repos")
        sut = FavoritesViewModel()
    }
    
    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: "favorite_repos")
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - Sample Data
    
    private func sampleRepo(id: Int = 1, name: String = "test-repo") -> GitHubRepo {
        GitHubRepo(
            id: id,
            name: name,
            fullName: "user/\(name)",
            description: "A test repository",
            stargazersCount: 100,
            language: "Swift",
            htmlUrl: "https://github.com/user/\(name)",
            forksCount: 10
        )
    }
    
    // MARK: - Initial State Tests
    
    func testInitialStateIsEmpty() {
        XCTAssertTrue(sut.favorites.isEmpty, "Favorites should be empty initially")
    }
    
    // MARK: - Add Favorite Tests
    
    func testAddFavorite() {
        // Given: A repository
        let repo = sampleRepo()
        
        // When: Adding to favorites
        sut.addFavorite(repo)
        
        // Then: It should be in favorites
        XCTAssertEqual(sut.favorites.count, 1)
        XCTAssertEqual(sut.favorites.first?.id, repo.id)
        XCTAssertEqual(sut.favorites.first?.name, repo.name)
    }
    
    func testAddDuplicateFavoriteIsIgnored() {
        // Given: A repository already in favorites
        let repo = sampleRepo()
        sut.addFavorite(repo)
        XCTAssertEqual(sut.favorites.count, 1)
        
        // When: Adding the same repo again
        sut.addFavorite(repo)
        
        // Then: Should still have only one
        XCTAssertEqual(sut.favorites.count, 1)
    }
    
    func testAddMultipleFavorites() {
        // Given: Multiple repositories
        let repo1 = sampleRepo(id: 1, name: "repo1")
        let repo2 = sampleRepo(id: 2, name: "repo2")
        let repo3 = sampleRepo(id: 3, name: "repo3")
        
        // When: Adding all to favorites
        sut.addFavorite(repo1)
        sut.addFavorite(repo2)
        sut.addFavorite(repo3)
        
        // Then: All should be in favorites
        XCTAssertEqual(sut.favorites.count, 3)
    }
    
    // MARK: - Remove Favorite Tests
    
    func testRemoveFavoriteByRepo() {
        // Given: A repository in favorites
        let repo = sampleRepo()
        sut.addFavorite(repo)
        XCTAssertEqual(sut.favorites.count, 1)
        
        // When: Removing by GitHubRepo
        sut.removeFavorite(repo)
        
        // Then: Should be empty
        XCTAssertTrue(sut.favorites.isEmpty)
    }
    
    func testRemoveFavoriteByFavouriteRepo() {
        // Given: A repository in favorites
        let repo = sampleRepo()
        sut.addFavorite(repo)
        let favoriteRepo = sut.favorites.first!
        
        // When: Removing by FavouriteRepo
        sut.removeFavorite(favoriteRepo)
        
        // Then: Should be empty
        XCTAssertTrue(sut.favorites.isEmpty)
    }
    
    func testRemoveNonExistentFavoriteDoesNothing() {
        // Given: One repo in favorites
        let repo1 = sampleRepo(id: 1)
        let repo2 = sampleRepo(id: 2)
        sut.addFavorite(repo1)
        
        // When: Removing a different repo
        sut.removeFavorite(repo2)
        
        // Then: Original should still be there
        XCTAssertEqual(sut.favorites.count, 1)
        XCTAssertEqual(sut.favorites.first?.id, 1)
    }
    
    // MARK: - Toggle Favorite Tests
    
    func testToggleFavoriteAddsWhenNotFavorite() {
        // Given: A repository not in favorites
        let repo = sampleRepo()
        
        // When: Toggling
        sut.toggleFavorite(repo)
        
        // Then: Should be added
        XCTAssertEqual(sut.favorites.count, 1)
        XCTAssertTrue(sut.isFavorite(repo))
    }
    
    func testToggleFavoriteRemovesWhenAlreadyFavorite() {
        // Given: A repository in favorites
        let repo = sampleRepo()
        sut.addFavorite(repo)
        XCTAssertTrue(sut.isFavorite(repo))
        
        // When: Toggling
        sut.toggleFavorite(repo)
        
        // Then: Should be removed
        XCTAssertTrue(sut.favorites.isEmpty)
        XCTAssertFalse(sut.isFavorite(repo))
    }
    
    // MARK: - isFavorite Tests
    
    func testIsFavoriteReturnsTrueForFavorite() {
        // Given: A repository in favorites
        let repo = sampleRepo()
        sut.addFavorite(repo)
        
        // Then: isFavorite should return true
        XCTAssertTrue(sut.isFavorite(repo))
    }
    
    func testIsFavoriteReturnsFalseForNonFavorite() {
        // Given: A repository NOT in favorites
        let repo = sampleRepo()
        
        // Then: isFavorite should return false
        XCTAssertFalse(sut.isFavorite(repo))
    }
    
    // MARK: - Persistence Tests
    
    func testFavoritesArePersistedToUserDefaults() {
        // Given: Adding a favorite
        let repo = sampleRepo()
        sut.addFavorite(repo)
        
        // When: Creating a new ViewModel (simulates app restart)
        let newViewModel = FavoritesViewModel()
        
        // Then: Favorites should be loaded from UserDefaults
        XCTAssertEqual(newViewModel.favorites.count, 1)
        XCTAssertEqual(newViewModel.favorites.first?.id, repo.id)
    }
    
    func testRemovalIsPersistedToUserDefaults() {
        // Given: A favorite that we then remove
        let repo = sampleRepo()
        sut.addFavorite(repo)
        sut.removeFavorite(repo)
        
        // When: Creating a new ViewModel
        let newViewModel = FavoritesViewModel()
        
        // Then: Should still be empty
        XCTAssertTrue(newViewModel.favorites.isEmpty)
    }
}
