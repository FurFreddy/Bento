import SwiftUI

// MARK: - 1. DATENMODELLE
// Hier erklären wir Swift, wie das JSON von e621 aufgebaut ist.
// "Codable" sorgt dafür, dass Swift das JSON automatisch in diese Struktur übersetzt!
struct E621Response: Codable {
    let posts: [Post]
}

struct Post: Identifiable, Codable {
    let id: Int
    let file: FileData
    let sample: SampleData
    
    struct FileData: Codable {
        let ext: String?
        let url: String?
    }
    
    struct SampleData: Codable {
        let url: String?
    }
    
    // Eine kleine Hilfsvariable: Wir versuchen die Sample-URL zu nehmen. 
    // Wenn es die nicht gibt, nehmen wir die normale File-URL.
    var previewUrl: URL? {
        if let urlString = sample.url ?? file.url {
            return URL(string: urlString)
        }
        return nil
    }
}

// MARK: - 2. NETZWERK-LOGIK
// Diese Klasse kümmert sich um den API-Aufruf. 
// "ObservableObject" bedeutet, dass sich das UI automatisch aktualisiert, wenn sich hier Daten ändern.
class PostFetcher: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    
    func fetch(tags: String = "") async {
        // UI-Aktualisierungen müssen im Main-Thread laufen
        await MainActor.run { 
            self.isLoading = true
            self.posts = [] 
        }
        
        // URL zusammenbauen (Tags müssen für URLs codiert werden, z.B. Leerzeichen zu %20)
        let safeTags = tags.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://e621.net/posts.json?limit=30&tags=\(safeTags)"
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        // WICHTIG: e621 blockiert Anfragen ohne User-Agent!
        request.setValue("Bento/1.0 (by iOS Learner)", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(E621Response.self, from: data)
            
            await MainActor.run {
                // Wir filtern Posts heraus, die keine gültige Bild-URL haben (z.B. gelöschte)
                self.posts = response.posts.filter { $0.previewUrl != nil }
                self.isLoading = false
            }
        } catch {
            print("Fehler beim Laden der API: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
}

// MARK: - 3. BENUTZEROBERFLÄCHE (UI)
struct ContentView: View {
    // Hier binden wir unsere Netzwerk-Logik an die View an
    @StateObject private var fetcher = PostFetcher()
    @State private var searchText = ""
    
    // Wir definieren ein flexibles Raster. 
    // Minimum 100 Pixel breit, Swift quetscht so viele Spalten rein wie möglich.
    let gridColumns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 8)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // --- SUCHLEISTE ---
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Tags suchen (z.B. cat)", text: $searchText)
                    // .onSubmit wird ausgelöst, wenn du auf der Tastatur "Enter" drückst
                        .onSubmit {
                            Task { await fetcher.fetch(tags: searchText) }
                        }
                }
                .padding(10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding()
                
                // --- GRID (RASTER) ---
                ScrollView {
                    if fetcher.isLoading {
                        ProgressView("Lade Bento...")
                            .padding(.top, 50)
                    } else {
                        LazyVGrid(columns: gridColumns, spacing: 8) {
                            ForEach(fetcher.posts) { post in
                                
                                // AsyncImage lädt Bilder automatisch im Hintergrund
                                AsyncImage(url: post.previewUrl) { phase in
                                    switch phase {
                                    case .empty:
                                        Color.gray.opacity(0.3) // Grauer Platzhalter beim Laden
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill() // Bild füllt den Kasten aus
                                    case .failure:
                                        Color.red.opacity(0.3) // Roter Kasten bei Fehler (z.B. kaputtes Bild)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                // Mache jeden Kasten genau 120 Pixel hoch
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                                .cornerRadius(8)
                                .clipped() // Schneidet alles ab, was über den Kasten hinausragt
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Bento")
            // .task wird automatisch ausgeführt, sobald die App startet
            .task {
                await fetcher.fetch()
            }
        }
    }
}

