import SwiftUI

@MainActor
class PostFetcher: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var canLoadMore = true
    private var currentPage = 1
    private var currentTags = ""
    
    func fetch(tags: String = "", reset: Bool = false) async {
        if reset {
            currentPage = 1
            posts = []
            currentTags = tags
            canLoadMore = true
        }
        
        guard !isLoading && canLoadMore else { return }
        
        isLoading = true
        
        let account = SettingsStore.shared.activeAccount
        let domain = account?.domain ?? "https://e621.net"
        let safeTags = currentTags.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Construct URL based on API type
        let urlString: String
        let type = account?.type ?? "e621"
        
        if type == "gelbooru" {
            urlString = "\(domain)/index.php?page=dapi&s=post&q=index&json=1&limit=50&pid=\(currentPage-1)&tags=\(safeTags)"
        } else {
            // Default for e621 and Danbooru
            urlString = "\(domain)/posts.json?limit=50&page=\(currentPage)&tags=\(safeTags)"
        }
        
        guard let url = URL(string: urlString) else { 
            isLoading = false
            return 
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bento/1.0 (Native iOS)", forHTTPHeaderField: "User-Agent")
        
        // Add Authorization if available
        if let username = account?.username, !username.isEmpty, let apiKey = account?.apiKey, !apiKey.isEmpty {
            if type == "e621" || type == "danbooru" {
                let auth = "\(username):\(apiKey)".data(using: .utf8)?.base64EncodedString() ?? ""
                request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
            }
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // Handle different JSON structures
            var fetchedPosts: [Post] = []
            if type == "gelbooru" {
                // Gelbooru returns an array directly or { post: [] }
                if let gelResponse = try? JSONDecoder().decode([Post].self, from: data) {
                    fetchedPosts = gelResponse
                } else if let gelObj = try? JSONDecoder().decode(GelbooruResponse.self, from: data) {
                    fetchedPosts = gelObj.post
                }
            } else {
                let response = try JSONDecoder().decode(E621Response.self, from: data)
                fetchedPosts = response.posts
            }
            
            if fetchedPosts.isEmpty {
                canLoadMore = false
            } else {
                self.posts.append(contentsOf: fetchedPosts.filter { $0.previewUrl != nil })
                currentPage += 1
            }
            isLoading = false
        } catch {
            print("Fetch error: \(error)")
            isLoading = false
        }
    }
}

// Support for Gelbooru JSON structure
struct GelbooruResponse: Codable {
    let post: [Post]
}
