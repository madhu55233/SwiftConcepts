//
//  SwiftConceptsApp.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 08/06/26.
//

import SwiftUI

@main
struct SwiftConceptsApp: App {
    
    // Create dependencies once at app level
    private let repository: GithubRepository
    @StateObject private var favoritesViewModel = FavoritesViewModel()
    
    init() {
        // Build the dependency chain
        let networkService = NetworkService.shared
        let realRepository = GitHubRepositoryImpl(network: networkService)
        let cachedRepository = CachedGithubRepository(real: realRepository)
        self.repository = cachedRepository
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView(repository: repository)
                .environmentObject(favoritesViewModel)
        }
    }
}
