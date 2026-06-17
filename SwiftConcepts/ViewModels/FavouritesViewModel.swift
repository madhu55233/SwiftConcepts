//
//  FavouritesViewModel.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 17/06/26.
//

import Foundation
import Combine

@MainActor
final class FavoritesViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var favorites: [FavouriteRepo] = []

    // MARK: - Persistence Key

    private let userDefaultsKey = "favorite_repos"

    // MARK: - Init

    init() {
        loadFavorites()
    }

    // MARK: - Public API

    func isFavorite(_ repo: GitHubRepo) -> Bool {
        favorites.contains { $0.id == repo.id }
    }

    func toggleFavorite(_ repo: GitHubRepo) {
        if isFavorite(repo) {
            removeFavorite(repo)
        } else {
            addFavorite(repo)
        }
    }

    func addFavorite(_ repo: GitHubRepo) {
        guard !isFavorite(repo) else { return }

        let favorite = FavouriteRepo(from: repo)
        favorites.append(favorite)
        saveFavorites()
    }

    func removeFavorite(_ repo: GitHubRepo) {
        favorites.removeAll { $0.id == repo.id }
        saveFavorites()
    }

    func removeFavorite(_ favorite: FavouriteRepo) {
        favorites.removeAll { $0.id == favorite.id }
        saveFavorites()
    }

    // MARK: - Persistence

    private func saveFavorites() {
        do {
            let data = try JSONEncoder().encode(favorites)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save favorites: \(error)")
        }
    }

    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }

        do {
            favorites = try JSONDecoder().decode([FavouriteRepo].self, from: data)
        } catch {
            print("Failed to load favorites: \(error)")
        }
    }
}
