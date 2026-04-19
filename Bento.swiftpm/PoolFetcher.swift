import Foundation
import SwiftUI

@MainActor
class PoolFetcher: ObservableObject {
    @Published var pools: [Pool] = []
    @Published var isLoading = false
    @Published var canLoadMore = true
    private var currentPage = 1
    
    func fetch(search: String = "", reset: Bool = false) async {
        if reset {
            currentPage = 1
            pools = []
            canLoadMore = true
        }
        
        guard !isLoading && canLoadMore else { return }
        
        isLoading = true
        
        let account = SettingsStore.shared.activeAccount
        let domain = account?.domain ?? "https://e621.net"
        let safeSearch = search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // e621 / Danbooru usually support /pools.json
        var urlString = "\(domain)/pools.json?limit=20&page=\(currentPage)"
        if !safeSearch.isEmpty {
            urlString += "&search[name_matches]=*\(safeSearch)*"
        }
        
        if let username = account?.username, !username.isEmpty, let apiKey = account?.apiKey, !apiKey.isEmpty {
            let safeUsername = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let safeApiKey = apiKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            urlString += "&login=\(safeUsername)&api_key=\(safeApiKey)"
        }
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bento/1.0 (Native iOS)", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let fetchedPools = try JSONDecoder().decode([Pool].self, from: data)
            
            if fetchedPools.isEmpty {
                canLoadMore = false
            } else {
                self.pools.append(contentsOf: fetchedPools)
                currentPage += 1
            }
        } catch {
            print("Fetch pools error: \(error)")
        }
        
        isLoading = false
    }
}
