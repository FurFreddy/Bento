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
        
        let safeTags = currentTags.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://e621.net/posts.json?limit=50&page=\(currentPage)&tags=\(safeTags)"
        
        guard let url = URL(string: urlString) else { 
            isLoading = false
            return 
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bento/1.0 (by iOS Learner, Native Migration)", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(E621Response.self, from: data)
            
            if response.posts.isEmpty {
                canLoadMore = false
            } else {
                let newPosts = response.posts.filter { $0.previewUrl != nil }
                self.posts.append(contentsOf: newPosts)
                currentPage += 1
            }
            isLoading = false
        } catch {
            print("Fetch error: \(error)")
            isLoading = false
        }
    }
}
