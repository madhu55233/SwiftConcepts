//
//  FavoritesView.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 17/06/26.
//

import SwiftUI

struct FavoritesView: View {
    
    @EnvironmentObject private var viewModel: FavoritesViewModel
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Favorites")
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.favorites.isEmpty {
            ContentUnavailableView(
                "No Favorites Yet",
                systemImage: "star",
                description: Text("Tap the star icon on any repository to save it here.")
            )
        } else {
            favoritesList
        }
    }
    
    private var favoritesList: some View {
        List {
            ForEach(viewModel.favorites) { favorite in
                FavoriteRowView(favorite: favorite)
            }
            .onDelete(perform: deleteFavorites)
        }
        .listStyle(.plain)
    }
    
    private func deleteFavorites(at offsets: IndexSet) {
        for index in offsets {
            let favorite = viewModel.favorites[index]
            viewModel.removeFavorite(favorite)
        }
    }
}

// MARK: - Favorite Row

struct FavoriteRowView: View {
    
    let favorite: FavouriteRepo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(favorite.name)
                .font(.headline)
            
            Text(favorite.fullName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Label("\(favorite.stargazersCount) stars", systemImage: "star")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FavoritesView()
        .environmentObject(FavoritesViewModel())
}
