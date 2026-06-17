# GitHub Repository Explorer — Complete Build Guide

A comprehensive iOS project demonstrating: **MVVM, async/await, Combine, DI, ARC, Closures, Pagination, Caching, Actors, and Unit Testing**.

---

## Table of Contents

1. [Step 1 — Models](#step-1--models)
2. [Step 2 — Networking + async/await](#step-2--networking--asyncawait)
3. [Step 3 — Protocols + Dependency Injection](#step-3--protocols--dependency-injection)
4. [Step 4 — ARC + Memory Management](#step-4--arc--memory-management)
5. [Step 5 — Closures](#step-5--closures)
6. [Step 6 — MVVM + Combine](#step-6--mvvm--combine)
7. [Step 7 — Views (SwiftUI)](#step-7--views-swiftui)
8. [Step 8 — Auth / Actor](#step-8--auth--actor)
9. [Step 9 — Unit Testing](#step-9--unit-testing)

---

## Project Structure

```
SwiftConcepts/
├── Models/
│   ├── GitHubUser.swift
│   ├── Repository.swift
│   ├── FavouriteRepository.swift
│   └── UserSearchResponse.swift
├── Networking/
│   ├── APIEndpoint.swift
│   ├── NetworkError.swift
│   ├── NetworkService.swift
│   └── TokenManager.swift
├── Repository/
│   ├── GitHubRepository.swift
│   ├── GitHubRepositoryImpl.swift
│   └── CachedGitHubRepository.swift
├── ViewModels/
│   ├── UserSearchViewModel.swift
│   ├── RepoListViewModel.swift
│   └── FavoritesViewModel.swift
├── Views/
│   ├── SwiftConceptsApp.swift
│   ├── MainTabView.swift
│   ├── UserSearchView.swift
│   ├── UserRowView.swift
│   ├── RepoListView.swift
│   ├── RepoRowView.swift
│   └── FavoritesView.swift
├── Utilities/
│   ├── Cache.swift
│   └── PaginationController.swift
└── Tests/
    ├── MockGithubRepository.swift
    ├── UserSearchViewModelTests.swift
    ├── FavoritesViewModelTests.swift
    └── RepoListViewModelTests.swift
```

---

# Step 1 — Models

## What are Models?

Models are plain Swift `struct`s that represent your data. They are the "truth" of what your app works with.

### Why Structs, Not Classes?

| Structs (Value Types) | Classes (Reference Types) |
|----------------------|---------------------------|
| Copied when passed around | Shared (same instance) |
| No ARC overhead | Need ARC to manage memory |
| Thread-safe by default | Can have race conditions |
| `Codable` auto-synthesized | `Codable` auto-synthesized |

**For data models, structs are almost always the right choice.**

---

## GitHubUser.swift

```swift
import Foundation

struct GitHubUser: Codable, Identifiable, Hashable {
    let id: Int
    let login: String          // GitHub username e.g. "octocat"
    let avatarUrl: String      // profile picture URL
    let htmlUrl: String        // link to GitHub profile

    // GitHub API returns snake_case, Swift uses camelCase
    // CodingKeys bridges the gap
    enum CodingKeys: String, CodingKey {
        case id
        case login
        case avatarUrl = "avatar_url"
        case htmlUrl   = "html_url"
    }
}
```

### Explanation of Each Protocol

**`Codable`** = `Encodable + Decodable`
- Allows automatic conversion between JSON and Swift structs
- No manual parsing needed — just `JSONDecoder().decode(GitHubUser.self, from: data)`

**`Identifiable`**
- Requires an `id` property
- SwiftUI's `List` and `ForEach` use this to track which rows to update
- Without it, the entire list re-renders on every change

**`Hashable`**
- Allows the struct to be used in `Set` or as `Dictionary` keys
- Enables efficient duplicate checking

**`CodingKeys`**
- Maps JSON keys to Swift property names
- `avatar_url` (JSON) → `avatarUrl` (Swift)
- Properties without explicit mapping use their name as-is

---

## Repository.swift (GitHubRepo)

```swift
import Foundation

struct GitHubRepo: Codable, Identifiable, Hashable {
    let id: Int
    let name: String                // repo name e.g. "swift"
    let fullName: String            // "apple/swift"
    let description: String?        // optional — some repos have no description
    let stargazersCount: Int        // ⭐ count
    let language: String?           // optional — some repos have no language set
    let htmlUrl: String             // link to repo on GitHub
    let forksCount: Int

    enum CodingKeys: String, CodingKey {
        case id, name, description, language
        case fullName       = "full_name"
        case stargazersCount = "stargazers_count"
        case htmlUrl        = "html_url"
        case forksCount     = "forks_count"
    }
}
```

### Why Some Properties Are Optional (`String?`)

Real-world APIs often have missing data:
- A new repo might not have a description yet
- Some repos don't specify a programming language

Using `String?` (Optional) handles this gracefully — the decoder won't crash if the field is `null` or missing.

---

## FavouriteRepository.swift

```swift
import Foundation

// This is what we PERSIST locally (UserDefaults)
// It's a lightweight version — we don't need to store everything
struct FavouriteRepo: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let fullName: String
    let stargazersCount: Int

    // Convenience init — convert a full GitHubRepo into a lightweight Favorite
    init(from repo: GitHubRepo) {
        self.id              = repo.id
        self.name            = repo.name
        self.fullName        = repo.fullName
        self.stargazersCount = repo.stargazersCount
    }
}
```

### Why a Separate Model?

**Separation of concerns:**
- `GitHubRepo` = network model (everything from the API)
- `FavouriteRepo` = persistence model (only what we need to save locally)

This way, if the API changes, your local storage isn't affected.

---

## UserSearchResponse.swift

```swift
import Foundation

// GitHub's search API wraps results in an envelope:
// { "total_count": 123, "items": [ ...users... ] }
struct UserSearchResponse: Codable {
    let totalCount: Int
    let items: [GitHubUser]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case items
    }
}
```

### Why an Envelope Model?

GitHub's search API doesn't return `[GitHubUser]` directly. It returns:

```json
{
  "total_count": 1234,
  "incomplete_results": false,
  "items": [ { "id": 1, "login": "octocat", ... }, ... ]
}
```

`UserSearchResponse` captures this structure. The `items` array is automatically decoded as `[GitHubUser]` because `GitHubUser` is `Codable`.

---

# Step 2 — Networking + async/await

## What is async/await?

`async/await` lets you write asynchronous code (network calls, file I/O) that **looks synchronous** — no callback hell, no deeply nested closures.

### The Old Way vs The New Way

```swift
// ❌ OLD WAY — completion handler (callback hell)
func fetchUser(completion: @escaping (Result<GitHubUser, Error>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        // nested inside a closure
        // hard to read
        // easy to forget to call completion
    }.resume()
}

// ✅ NEW WAY — async/await
func fetchUser() async throws -> GitHubUser {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(GitHubUser.self, from: data)
    // reads top to bottom, like synchronous code
}
```

### Key Keywords

| Keyword | Meaning |
|---------|---------|
| `async` | This function can be suspended (paused) while waiting |
| `await` | Pause here until the result is ready, but don't block the thread |
| `throws` | This function can fail, caller must use `try` |
| `try` | "I know this might fail, handle the error" |

---

## APIEndpoint.swift

This defines **what** to call — keeps URLs and parameters in one place.

```swift
import Foundation

enum APIEndpoint {
    case searchUser(query: String, page: Int)
    case userRepos(username: String, page: Int)

    // GitHub API base
    private static let base = "https://api.github.com"
    private static let perPage = 20

    // Build the full URL for each case
    var url: URL {
        switch self {
        case .searchUser(let query, let page):
            // GET /search/users?q=octocat&per_page=20&page=1
            var components = URLComponents(string: "\(Self.base)/search/users")!
            components.queryItems = [
                URLQueryItem(name: "q",        value: query),
                URLQueryItem(name: "per_page", value: "\(Self.perPage)"),
                URLQueryItem(name: "page",     value: "\(page)")
            ]
            return components.url!

        case .userRepos(let username, let page):
            // GET /users/octocat/repos?per_page=20&page=1&sort=stars
            var components = URLComponents(string: "\(Self.base)/users/\(username)/repos")!
            components.queryItems = [
                URLQueryItem(name: "per_page", value: "\(Self.perPage)"),
                URLQueryItem(name: "page",     value: "\(page)"),
                URLQueryItem(name: "sort",     value: "stars")
            ]
            return components.url!
        }
    }

    // Build a URLRequest with headers
    func urlRequest(token: String?) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        // Add auth token if available (increases rate limit from 60 to 5000 req/hour)
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}
```

### Why an Enum with Associated Values?

Each API endpoint has different parameters:
- `searchUser` needs a `query` and `page`
- `userRepos` needs a `username` and `page`

Enums with associated values let you express this type-safely:

```swift
let endpoint = APIEndpoint.searchUser(query: "swift", page: 1)
// The compiler ensures you provide both query AND page
```

### Why URLComponents?

`URLComponents` safely builds URLs:
- Handles special characters (spaces become `%20`)
- Properly escapes query parameters
- Prevents URL injection attacks

---

## NetworkError.swift

Always define your own error types — gives you clear, human-readable errors.

```swift
import Foundation

enum NetworkError: LocalizedError {
    case invalidResponse                  // server didn't return HTTP response
    case httpError(statusCode: Int)       // e.g. 401 Unauthorized, 404 Not Found
    case decodingError(Error)             // JSON didn't match our model
    case noInternet                       // device is offline

    // LocalizedError gives us a nice message for the UI
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .httpError(let code):
            return "Server returned error code \(code)."
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .noInternet:
            return "No internet connection. Showing cached results."
        }
    }
}
```

### Why Custom Errors?

- `URLError` codes like `-1009` mean nothing to users
- Custom errors let you show "No internet connection" instead
- `LocalizedError` conformance means SwiftUI can display `error.localizedDescription` directly

---

## NetworkService.swift

The **single place** that actually makes HTTP calls.

```swift
import Foundation

final class NetworkService {
    
    // Singleton — one instance shared app-wide
    static let shared = NetworkService()
    private let tokenManager = TokenManager.shared
    
    private init() {}   // private init enforces singleton usage
    
    // MARK: - Generic Fetch
    
    // T is a placeholder: "whatever the caller expects back"
    func fetch<T: Decodable>(
            _ endpoint: APIEndpoint,
            token: String? = nil
    ) async throws -> T {
        let request = endpoint.urlRequest(token: token)
        
        // await — suspends this function, frees the thread
        // Swift resumes here when the response arrives
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Cast to HTTPURLResponse to read the status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // Handle HTTP errors before trying to decode
        switch httpResponse.statusCode {
        case 200...299:
            break   // success — continue to decoding
        case 401:
            throw NetworkError.httpError(statusCode: 401)  // Unauthorized
        case 403:
            throw NetworkError.httpError(statusCode: 403)  // Rate limited
        case 404:
            throw NetworkError.httpError(statusCode: 404)  // Not found
        default:
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Decode JSON → Swift struct
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    // MARK: - Fetch with automatic auth
    
    func fetchWithAuth<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let token: String?
        do {
            token = try await tokenManager.validToken()
        } catch {
            token = nil
        }
        
        do {
            return try await fetch(endpoint, token: token)
        } catch NetworkError.httpError(statusCode: 401) {
            await tokenManager.clearToken()
            return try await fetch(endpoint, token: nil)
        }
    }
}
```

### What are Generics (`<T: Decodable>`)?

Generics let you write **one function** that works with **many types**:

```swift
// Without generics — you'd need a function for each type:
func fetchUsers() async throws -> [GitHubUser] { ... }
func fetchRepos() async throws -> [GitHubRepo] { ... }
func fetchResponse() async throws -> UserSearchResponse { ... }

// With generics — one function handles all:
func fetch<T: Decodable>() async throws -> T { ... }

// Usage:
let users: [GitHubUser] = try await fetch(.searchUser(...))
let repos: [GitHubRepo] = try await fetch(.userRepos(...))
```

The `T: Decodable` constraint means "T can be any type, as long as it's Decodable."

### What is a Singleton?

A singleton ensures **only one instance** exists app-wide:

```swift
static let shared = NetworkService()  // The one instance
private init() {}                      // No one else can create instances

// Usage everywhere:
NetworkService.shared.fetch(...)
```

**Why?** `URLSession` internally manages connection pooling. One `NetworkService` = one connection pool = efficient reuse.

---

# Step 3 — Protocols + Dependency Injection

## What is a Protocol?

A protocol defines **what** something can do, without saying **how**. It's a contract.

```swift
protocol GithubRepository {
    func searchUsers(query: String, page: Int) async throws -> [GitHubUser]
    func fetchRepos(for userName: String, page: Int) async throws -> [GitHubRepo]
}
```

Any type that conforms to `GithubRepository` **must** implement these two methods.

## What is Dependency Injection (DI)?

DI means you **pass in** the things a class needs, rather than letting it create them itself.

### Without DI (Bad)

```swift
class UserSearchViewModel {
    func search(query: String) async {
        // Hardcoded — directly uses the singleton
        let result = try await NetworkService.shared.fetch(...)
    }
}
```

**Problems:**
- Can't test without hitting real network
- Can't swap for a cached version
- Can't use a mock for unit tests

### With DI (Good)

```swift
class UserSearchViewModel {
    let repository: GithubRepository   // Just a protocol — could be anything
    
    init(repository: GithubRepository) {
        self.repository = repository   // Passed in from outside
    }
}
```

**Benefits:**
- Pass `GitHubRepositoryImpl` for production
- Pass `MockGithubRepository` for tests
- Pass `CachedGithubRepository` for offline mode

### The Analogy

> **Without DI:** "I need to make a phone call. Let me walk to the kitchen and find a phone."
>
> **With DI:** "I need to make a phone call. Hand me a phone." — You don't care where it came from.

---

## GithubRepository.swift (The Protocol)

```swift
import Foundation

protocol GithubRepository {
    // Search GitHub users by username query
    func searchUsers(query: String, page: Int) async throws -> [GitHubUser]
    
    // Fetch repos belonging to a user
    func fetchRepos(for userName: String, page: Int) async throws -> [GitHubRepo]
}
```

---

## GitHubRepositoryImpl.swift (Real Implementation)

```swift
import Foundation

final class GitHubRepositoryImpl: GithubRepository {
    
    private let network: NetworkService
    
    // NetworkService is INJECTED — not hardcoded
    init(network: NetworkService = .shared) {
        self.network = network
    }
    
    func searchUsers(query: String, page: Int) async throws -> [GitHubUser] {
        let response: UserSearchResponse = try await network.fetch(
            .searchUser(query: query, page: page)
        )
        return response.items
    }
    
    func fetchRepos(for userName: String, page: Int) async throws -> [GitHubRepo] {
        return try await network.fetch(
            .userRepos(username: userName, page: page)
        )
    }
}
```

---

## CachedGithubRepository.swift (Decorator Pattern)

```swift
import Foundation

final class CachedGithubRepository: GithubRepository {
    
    private let real: GithubRepository          // The real impl underneath
    private var userCache: [String: [GitHubUser]] = [:]
    private var repoCache: [String: [GitHubRepo]] = [:]
    
    init(real: GithubRepository) {
        self.real = real
    }
    
    func searchUsers(query: String, page: Int) async throws -> [GitHubUser] {
        let key = "\(query.lowercased())_page\(page)"
        
        // Cache hit — return immediately, no network call
        if let cached = userCache[key] {
            print("✅ Cache hit: \(key)")
            return cached
        }
        
        // Cache miss — fetch from real repository, then store
        print("🌐 Network fetch: \(key)")
        let users = try await real.searchUsers(query: query, page: page)
        userCache[key] = users
        return users
    }
    
    func fetchRepos(for userName: String, page: Int) async throws -> [GitHubRepo] {
        let key = "\(userName.lowercased())_page\(page)"
        
        if let cached = repoCache[key] {
            return cached
        }
        
        let repos = try await real.fetchRepos(for: userName, page: page)
        repoCache[key] = repos
        return repos
    }
}
```

### What is the Decorator Pattern?

The Decorator **wraps** another object and adds behavior:

```
CachedGithubRepository  ──wraps──►  GitHubRepositoryImpl  ──uses──►  NetworkService
        │                                    │
        └── checks cache first               └── actually calls API
```

---

# Step 4 — ARC + Memory Management

## What is ARC?

**ARC (Automatic Reference Counting)** is how Swift automatically frees memory.

Every time you create a class instance, Swift counts how many references point to it. When the count hits zero, Swift deallocates it.

```swift
var ref1: Person? = Person(name: "Alice")   // count = 1
var ref2 = ref1                              // count = 2
ref1 = nil                                   // count = 1
ref2 = nil                                   // count = 0 → deallocated!
```

## The Problem: Retain Cycles

A **retain cycle** happens when two objects hold strong references to each other:

```swift
class Person {
    var pet: Pet?        // strong reference to Pet
}

class Pet {
    var owner: Person?   // strong reference back — CYCLE!
}
```

**Neither is ever deallocated — MEMORY LEAK!**

## The Solution: `weak` and `unowned`

| Keyword | Reference Count | When to Use |
|---------|-----------------|-------------|
| `strong` (default) | +1 | Owner of the object |
| `weak` | 0 (doesn't count) | Back-reference, becomes `nil` on dealloc |
| `unowned` | 0 (doesn't count) | Back-reference, crashes if accessed after dealloc |

### Where You Need `[weak self]`

In Combine sinks and closures:

```swift
$searchText
    .sink { [weak self] query in    // ← [weak self] here!
        self?.performSearch(query)
    }
    .store(in: &cancellables)
```

---

# Step 5 — Closures

## What is a Closure?

A closure is a **self-contained block of code** you can pass around and execute later.

```swift
// A function
func add(a: Int, b: Int) -> Int { a + b }

// Same thing as a closure
let addClosure: (Int, Int) -> Int = { $0 + $1 }
```

## Three Main Uses

### 1. Completion Handlers
```swift
func fetchData(completion: @escaping (Result<Data, Error>) -> Void)
```

### 2. Higher-Order Functions
```swift
let doubled = [1, 2, 3].map { $0 * 2 }  // [2, 4, 6]
```

### 3. Stored Callbacks
```swift
var onTap: (() -> Void)?
```

## `@escaping`

Mark closures `@escaping` when they're stored or called later:

```swift
func doLater(action: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        action()
    }
}
```

---

# Step 6 — MVVM + Combine

## MVVM Layers

```
VIEW (SwiftUI) — displays data, sends actions
      ↓
VIEWMODEL — owns state (@Published), contains logic
      ↓
MODEL/REPOSITORY — data layer
```

## Combine Basics

```swift
$searchText                              // Publisher
    .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
    .removeDuplicates()
    .sink { [weak self] query in ... }   // Subscriber
    .store(in: &cancellables)
```

## Combine Operators

| Operator | What It Does |
|----------|--------------|
| `.debounce` | Wait until values stop |
| `.removeDuplicates()` | Ignore consecutive duplicates |
| `.map { }` | Transform values |
| `.sink { }` | Subscribe |

---

# Step 7 — Views (SwiftUI)

## Property Wrappers

| Wrapper | Who Creates | Who Modifies |
|---------|-------------|--------------|
| `@State` | View | View |
| `@StateObject` | View creates ViewModel | ViewModel |
| `@ObservedObject` | Parent passes | ViewModel |
| `@EnvironmentObject` | Ancestor injects | ViewModel |
| `@Binding` | Parent creates | Both |

## Key SwiftUI Patterns

**`$viewModel.searchText`** — Two-way binding

**`.onAppear { }`** — Called when view appears

**`AsyncImage`** — Load images from URL

---

# Step 8 — Auth / Actor

## What is an Actor?

An `actor` guarantees only one piece of code accesses its state at a time.

```swift
actor TokenManager {
    var token: String?
    
    func validToken() async throws -> String {
        // Only one caller at a time
    }
}
```

Use `await` to call actor methods:

```swift
await tokenManager.validToken()
```

---

# Step 9 — Unit Testing

## Why Mocks?

DI lets you swap real implementations with mocks:

```swift
// Production
let vm = UserSearchViewModel(repository: GitHubRepositoryImpl())

// Test
let vm = UserSearchViewModel(repository: MockGithubRepository())
```

## Test Structure

```swift
func testSomething() {
    // Given — setup
    mockRepository.stubbedUsers = [...]
    
    // When — action
    sut.searchText = "test"
    
    // Then — verify
    XCTAssertEqual(sut.users.count, 1)
}
```

---

# Summary — Concept to File Mapping

| Concept | Files | How Used |
|---------|-------|----------|
| **Models** | `Models/*.swift` | JSON ↔ Swift structs |
| **async/await** | `NetworkService.swift` | All async operations |
| **Protocols + DI** | `GithubRepository.swift` | Swap implementations |
| **ARC** | Combine sinks | `[weak self]` |
| **Closures** | Callbacks | Event handling |
| **MVVM** | ViewModels + Views | Separation |
| **Combine** | `UserSearchViewModel` | Debounce |
| **Caching** | `CachedGithubRepository` | Decorator |
| **Actor** | `TokenManager` | Thread-safe |
| **Testing** | `Tests/` | Mock via DI |

---

# Data Flow

```
User types "swift"
       ↓
$searchText emits
       ↓
.debounce waits 500ms
       ↓
ViewModel calls repository
       ↓
Cache checks → miss → NetworkService
       ↓
GitHub API returns JSON
       ↓
Decode → Store in cache
       ↓
ViewModel sets users
       ↓
@Published emits
       ↓
SwiftUI re-renders
```

---

# How to Run

1. Open `SwiftConcepts.xcodeproj`
2. Select iPhone simulator
3. Press **Cmd+R**
4. Search for GitHub users!

---

*Complete iOS Architecture Tutorial — MVVM, async/await, Combine, DI, ARC, Closures, Caching, Actors, Unit Testing*
