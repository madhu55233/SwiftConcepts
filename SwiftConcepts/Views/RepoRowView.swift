//
//  RepoRowView.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 17/06/26.
//

import SwiftUI

struct RepoRowView: View {
    
    let repo: GitHubRepo
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row: name + favorite button
            HStack {
                Text(repo.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Button {
                    onFavoriteToggle()
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? .yellow : .gray)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            
            // Description
            if let description = repo.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Stats row
            HStack(spacing: 16) {
                // Stars
                Label("\(repo.stargazersCount)", systemImage: "star")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Forks
                Label("\(repo.forksCount)", systemImage: "tuningfork")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Language
                if let language = repo.language {
                    Label(language, systemImage: "chevron.left.forwardslash.chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RepoRowView(
        repo: GitHubRepo(
            id: 1,
            name: "swift",
            fullName: "apple/swift",
            description: "The Swift Programming Language",
            stargazersCount: 65000,
            language: "Swift",
            htmlUrl: "https://github.com/apple/swift",
            forksCount: 10000
        ),
        isFavorite: true,
        onFavoriteToggle: {}
    )
    .padding()
}
