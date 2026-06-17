//
//  UserRowView.swift
//  SwiftConcepts
//
//  Created by Madhumitha on 17/06/26.
//

import SwiftUI

struct UserRowView: View {
    
    let user: GitHubUser
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: user.avatarUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 50, height: 50)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                case .failure:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            
            // Username
            VStack(alignment: .leading, spacing: 4) {
                Text(user.login)
                    .font(.headline)
                
                Text("View repositories →")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    UserRowView(user: GitHubUser(
        id: 1,
        login: "octocat",
        avatarUrl: "https://avatars.githubusercontent.com/u/583231",
        htmlUrl: "https://github.com/octocat"
    ))
    .padding()
}
