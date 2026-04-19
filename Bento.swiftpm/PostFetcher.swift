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
            isLoading = false
        }
        
        guard !isLoading && canLoadMore else { return }
        
        isLoading = true
        
        let account = SettingsStore.shared.activeAccount
        let domain = account?.domain ?? "https://e621.net"
        let type = account?.type ?? "e621"
        
        let translatedTags = Self.translateTags(currentTags, for: type, username: account?.username)
        let safeTags = translatedTags.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Construct URL based on API type
        var urlString: String
        
        if type == "gelbooru" {
            urlString = "\(domain)/index.php?page=dapi&s=post&q=index&json=1&limit=50&pid=\(currentPage-1)&tags=\(safeTags)"
            if let username = account?.username, !username.isEmpty, let apiKey = account?.apiKey, !apiKey.isEmpty {
                urlString += "&user_id=\(username)&api_key=\(apiKey)"
            }
        } else {
            // Default for e621 and Danbooru
            urlString = "\(domain)/posts.json?limit=50&page=\(currentPage)&tags=\(safeTags)"
            if let username = account?.username, !username.isEmpty, let apiKey = account?.apiKey, !apiKey.isEmpty {
                urlString += "&login=\(username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&api_key=\(apiKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            }
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
    
    // API Translation Logic
    static func translateTags(_ tags: String, for type: String, username: String?) -> String {
        var translated = tags
        
        // Favorites mapping
        if translated == "fav:" || translated == "fav" {
            translated = "fav:\(username ?? "")"
        }
        
        // Sorting conversion
        if type == "gelbooru" {
            translated = translated.replacingOccurrences(of: "order:score", with: "sort:score:desc")
            translated = translated.replacingOccurrences(of: "order:random", with: "sort:random")
            translated = translated.replacingOccurrences(of: "order:id_desc", with: "sort:id:desc")
            translated = translated.replacingOccurrences(of: "order:rank", with: "sort:score:desc")
        } else {
            // danbooru & e621
            translated = translated.replacingOccurrences(of: "sort:score:desc", with: "order:score")
            translated = translated.replacingOccurrences(of: "sort:score", with: "order:score")
            translated = translated.replacingOccurrences(of: "sort:random", with: "order:random")
            translated = translated.replacingOccurrences(of: "sort:id:desc", with: "order:id_desc")
        }
        
        return translated.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Autocomplete Suggestions
    @Published var suggestions: [String] = []
    private var searchTask: Task<Void, Never>?
    
    func fetchSuggestions(for prefix: String) {
        searchTask?.cancel()
        
        guard prefix.count > 1 else {
            self.suggestions = []
            return
        }
        
        searchTask = Task {
            let account = SettingsStore.shared.activeAccount
            let domain = account?.domain ?? "https://e621.net"
            let type = account?.type ?? "e621"
            let safePrefix = prefix.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            
            var urlString = ""
            if type == "gelbooru" {
                urlString = "\(domain)/index.php?page=dapi&s=tag&q=index&json=1&name_pattern=%\(safePrefix)%&orderby=count&limit=10"
            } else {
                urlString = "\(domain)/tags.json?search[name_matches]=*\(safePrefix)*&search[order]=count&limit=10"
            }
            
            guard let url = URL(string: urlString) else { return }
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
                let (data, response) = try await URLSession.shared.data(for: request)
                guard !Task.isCancelled else { return }
                
                if type == "gelbooru" {
                    if let gelObj = try? JSONDecoder().decode(GelbooruTagResponse.self, from: data) {
                        DispatchQueue.main.async { self.suggestions = gelObj.tag.map { $0.name } }
                    } else if let gelArr = try? JSONDecoder().decode([GelbooruTag].self, from: data) {
                        DispatchQueue.main.async { self.suggestions = gelArr.map { $0.name } }
                    }
                } else if type == "danbooru" {
                    if let danArr = try? JSONDecoder().decode([DanbooruTag].self, from: data) {
                        DispatchQueue.main.async { self.suggestions = danArr.map { $0.name } }
                    }
                } else { // e621
                    if let e6Arr = try? JSONDecoder().decode([DanbooruTag].self, from: data) {
                        DispatchQueue.main.async { self.suggestions = e6Arr.map { $0.name } }
                    }
                }
            } catch {
                print("Suggestion error: \(error)")
            }
        }
    }
}

struct GelbooruTagResponse: Codable {
    let tag: [GelbooruTag]
}

struct GelbooruTag: Codable {
    let name: String
}

struct DanbooruTag: Codable {
    let name: String
}


// Support for Gelbooru JSON structure
struct GelbooruResponse: Codable {
    let post: [Post]
}
