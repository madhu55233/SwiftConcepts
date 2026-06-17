//
//  MainTabView.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 17/06/26.
//

import SwiftUI

struct MainTabView: View {
    
    let repository: GithubRepository
    
    var body: some View {
        TabView {
            UserSearchView(repository: repository)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "star.fill")
                }
        }
    }
}
