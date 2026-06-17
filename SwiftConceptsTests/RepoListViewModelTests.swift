//
//  RepoListViewModelTests.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 17/06/26.
//

import XCTest
@testable import SwiftConcepts

/// Unit tests for RepoListViewModel
/// Tests repository loading, pagination, and error handling
@MainActor
final class RepoListViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: RepoListViewModel!
    private var mockRepository: MockGithubRepository!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockGithubRepository()
        sut = RepoListViewModel(repository: mockRepository, username: "octocat")
    }
    
    override func tearDown() async throws {
        sut = nil
        mockRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertTrue(sut.repos.isEmpty, "Repos should be empty initially")
        XCTAssertFalse(sut.isLoading, "Should not be loading initially")
        XCTAssertNil(sut.errorMessage, "Should have no error initially")
    }
    
    // MARK: - Load Tests
    
    func testLoadInitialReposPopulatesRepos() async {
        // Given: Mock repository returns repos
        let expectedRepos = [
            MockGithubRepository.sampleRepo(id: 1, name: "repo1"),
            MockGithubRepository.sampleRepo(id: 2, name: "repo2"),
            MockGithubRepository.sampleRepo(id: 3, name: "repo3")
        ]
        mockRepository.stubbedRepos = expectedRepos
        
        // When: Loading initial repos
        await sut.loadInitialRepos()
        
        // Then: Repos should be populated
        XCTAssertEqual(sut.repos.count, 3)
        XCTAssertEqual(sut.repos.first?.name, "repo1")
        XCTAssertFalse(sut.isLoading)
    }
    
    func testLoadInitialReposUsesCorrectUsername() async {
        // Given: Mock repository
        mockRepository.stubbedRepos = [MockGithubRepository.sampleRepo()]
        
        // When: Loading repos
        await sut.loadInitialRepos()
        
        // Then: Should use the username from init
        XCTAssertEqual(mockRepository.lastFetchUsername, "octocat")
        XCTAssertEqual(mockRepository.lastFetchPage, 1)
    }
    
    func testLoadInitialReposHandlesError() async {
        // Given: Mock repository throws error
        mockRepository.stubbedError = NetworkError.httpError(statusCode: 500)
        
        // When: Loading repos
        await sut.loadInitialRepos()
        
        // Then: Error should be captured
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.repos.isEmpty)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testLoadInitialReposResetsState() async {
        // Given: We already have repos
        mockRepository.stubbedRepos = [MockGithubRepository.sampleRepo(id: 1)]
        await sut.loadInitialRepos()
        XCTAssertEqual(sut.repos.count, 1)
        
        // When: Loading initial repos again with different data
        mockRepository.stubbedRepos = [
            MockGithubRepository.sampleRepo(id: 2),
            MockGithubRepository.sampleRepo(id: 3)
        ]
        await sut.loadInitialRepos()
        
        // Then: Should have new repos, not appended
        XCTAssertEqual(sut.repos.count, 2)
        XCTAssertEqual(sut.repos.first?.id, 2)
    }
    
    // MARK: - Pagination Tests
    
    func testLoadMoreIfNeededTriggersLoadNearEnd() async {
        // Given: 20 repos (full page)
        let repos = (1...20).map { MockGithubRepository.sampleRepo(id: $0, name: "repo\($0)") }
        mockRepository.stubbedRepos = repos
        await sut.loadInitialRepos()
        
        // When: Checking a repo near the end (threshold is count - 3)
        let nearEndRepo = sut.repos[17]  // Index 17 of 20
        sut.loadMoreIfNeeded(currentRepo: nearEndRepo)
        
        // Wait for async load
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Should have requested page 2
        XCTAssertEqual(mockRepository.lastFetchPage, 2)
    }
    
    func testLoadMoreIfNeededDoesNotTriggerInMiddle() async {
        // Given: 20 repos
        let repos = (1...20).map { MockGithubRepository.sampleRepo(id: $0, name: "repo\($0)") }
        mockRepository.stubbedRepos = repos
        await sut.loadInitialRepos()
        
        let initialCallCount = mockRepository.fetchReposCallCount
        
        // When: Checking a repo in the middle
        let middleRepo = sut.repos[5]
        sut.loadMoreIfNeeded(currentRepo: middleRepo)
        
        // Wait a bit
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Should NOT have loaded more
        XCTAssertEqual(mockRepository.fetchReposCallCount, initialCallCount)
    }
    
    func testNoDuplicatesOnPagination() async {
        // Given: First page
        let page1 = (1...20).map { MockGithubRepository.sampleRepo(id: $0) }
        mockRepository.stubbedRepos = page1
        await sut.loadInitialRepos()
        
        // When: Loading second page that contains duplicate id
        let page2WithDuplicate = [
            MockGithubRepository.sampleRepo(id: 20),  // duplicate
            MockGithubRepository.sampleRepo(id: 21),
            MockGithubRepository.sampleRepo(id: 22)
        ]
        mockRepository.stubbedRepos = page2WithDuplicate
        sut.loadNextPage()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Should not have duplicate id 20
        let idsWithValue20 = sut.repos.filter { $0.id == 20 }
        XCTAssertEqual(idsWithValue20.count, 1, "Should not have duplicate repos")
        XCTAssertEqual(sut.repos.count, 22, "Should have 20 + 2 unique = 22")
    }
    
    // MARK: - Loading State Tests
    
    func testIsLoadingDuringFetch() async {
        // Given: A slow network call
        mockRepository.simulatedDelay = 500_000_000  // 0.5 seconds
        mockRepository.stubbedRepos = [MockGithubRepository.sampleRepo()]
        
        // When: Starting load
        let loadTask = Task {
            await sut.loadInitialRepos()
        }
        
        // Small delay to let the load start
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Should be loading
        XCTAssertTrue(sut.isLoading, "Should be loading during fetch")
        
        // Wait for completion
        await loadTask.value
        XCTAssertFalse(sut.isLoading, "Should not be loading after fetch")
    }
}
