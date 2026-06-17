//
//  UserSearchViewModelTests.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 17/06/26.
//

import XCTest
@testable import SwiftConcepts

/// Unit tests for UserSearchViewModel
/// Tests search functionality, pagination, and error handling
@MainActor
final class UserSearchViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: UserSearchViewModel!  // System Under Test
    private var mockRepository: MockGithubRepository!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockGithubRepository()
        sut = UserSearchViewModel(repository: mockRepository)
    }
    
    override func tearDown() async throws {
        sut = nil
        mockRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        // Given: A new ViewModel
        // Then: It should have empty state
        XCTAssertTrue(sut.users.isEmpty, "Users should be empty initially")
        XCTAssertFalse(sut.isLoading, "Should not be loading initially")
        XCTAssertNil(sut.errorMessage, "Should have no error initially")
        XCTAssertFalse(sut.hasSearched, "Should not have searched initially")
        XCTAssertTrue(sut.searchText.isEmpty, "Search text should be empty initially")
    }
    
    // MARK: - Search Tests
    
    func testSearchPopulatesUsers() async throws {
        // Given: Mock repository returns users
        let expectedUsers = [
            MockGithubRepository.sampleUser(id: 1, login: "user1"),
            MockGithubRepository.sampleUser(id: 2, login: "user2"),
            MockGithubRepository.sampleUser(id: 3, login: "user3")
        ]
        mockRepository.stubbedUsers = expectedUsers
        
        // When: User searches
        sut.searchText = "test"
        
        // Wait for debounce (500ms) + network call
        try await Task.sleep(nanoseconds: 700_000_000)
        
        // Then: Users should be populated
        XCTAssertEqual(sut.users.count, 3, "Should have 3 users")
        XCTAssertEqual(sut.users.first?.login, "user1")
        XCTAssertTrue(sut.hasSearched, "Should have searched")
        XCTAssertFalse(sut.isLoading, "Should not be loading after search")
    }
    
    func testSearchHandlesError() async throws {
        // Given: Mock repository throws error
        mockRepository.stubbedError = NetworkError.httpError(statusCode: 500)
        
        // When: User searches
        sut.searchText = "test"
        
        // Wait for debounce + network call
        try await Task.sleep(nanoseconds: 700_000_000)
        
        // Then: Error should be captured
        XCTAssertNotNil(sut.errorMessage, "Should have error message")
        XCTAssertTrue(sut.users.isEmpty, "Should have no users on error")
    }
    
    func testEmptySearchClearsResults() async throws {
        // Given: We have some users from a previous search
        mockRepository.stubbedUsers = [MockGithubRepository.sampleUser()]
        sut.searchText = "test"
        try await Task.sleep(nanoseconds: 700_000_000)
        XCTAssertFalse(sut.users.isEmpty, "Should have users")
        
        // When: Search is cleared
        sut.searchText = ""
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Results should be cleared
        XCTAssertTrue(sut.users.isEmpty, "Users should be cleared")
        XCTAssertFalse(sut.hasSearched, "hasSearched should be false")
    }
    
    func testClearSearchResetsState() async throws {
        // Given: We have search results
        mockRepository.stubbedUsers = [MockGithubRepository.sampleUser()]
        sut.searchText = "test"
        try await Task.sleep(nanoseconds: 700_000_000)
        
        // When: clearSearch is called
        sut.clearSearch()
        
        // Then: All state should be reset
        XCTAssertTrue(sut.searchText.isEmpty)
        XCTAssertTrue(sut.users.isEmpty)
        XCTAssertFalse(sut.hasSearched)
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - Debounce Tests
    
    func testSearchDebouncesProperly() async throws {
        // Given: Mock repository
        mockRepository.stubbedUsers = [MockGithubRepository.sampleUser()]
        
        // When: User types multiple characters quickly
        sut.searchText = "s"
        sut.searchText = "sw"
        sut.searchText = "swi"
        sut.searchText = "swift"
        
        // Wait less than debounce time
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: No search should have happened yet
        XCTAssertEqual(mockRepository.searchUsersCallCount, 0, "Should not search during typing")
        
        // Wait for debounce to complete
        try await Task.sleep(nanoseconds: 600_000_000)
        
        // Then: Only one search should have happened
        XCTAssertEqual(mockRepository.searchUsersCallCount, 1, "Should only search once after debounce")
        XCTAssertEqual(mockRepository.lastSearchQuery, "swift", "Should search for final text")
    }
    
    // MARK: - Pagination Tests
    
    func testLoadMoreTriggersNextPage() async throws {
        // Given: First page of results
        let page1Users = (1...20).map { MockGithubRepository.sampleUser(id: $0, login: "user\($0)") }
        mockRepository.stubbedUsers = page1Users
        
        sut.searchText = "test"
        try await Task.sleep(nanoseconds: 700_000_000)
        
        XCTAssertEqual(sut.users.count, 20)
        
        // When: Load more is triggered near the end
        let lastUser = sut.users.last!
        sut.loadMoreIfNeeded(currentUser: lastUser)
        
        // Then: Second page should be requested
        try await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertEqual(mockRepository.lastSearchPage, 2, "Should request page 2")
    }
}
