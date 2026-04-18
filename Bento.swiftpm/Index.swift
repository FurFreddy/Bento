import SwiftUI
import UIKit

struct Index: View {
    @StateObject private var fetcher = PostFetcher()
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var settings = SettingsStore.shared
    
    @State private var searchText = ""
    @Namespace private var animationNamespace
    
    @State private var selectedPost: Post?
    @State private var showViewer = false
    @State private var showSettings = false
    @State private var showFilters = false // NEU: Filter Modal
    
    @State private var isSearchExpanded = false
    
    var body: some View {
        ZStack {
            theme.current.cBgMain.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header Area
                    HeaderArea(onSettings: { showSettings = true })
                    
                    // Search Bar Area mit Filter-Button
                    HStack {
                        SearchArea(text: $searchText, isExpanded: $isSearchExpanded) {
                            Task { await fetcher.fetch(tags: searchText, reset: true) }
                        }
                        
                        // NEU: Filter Button
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            showFilters = true
                        }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title2)
                                .foregroundColor(theme.current.cAccent)
                        }
                        .padding(.trailing, 16)
                    }
                    
                    // HERO SECTION
                    if let first = fetcher.posts.first, searchText.isEmpty {
                        HeroSection(post: first)
                    }
                    
                    // MAIN GRID
                    if fetcher.isLoading && fetcher.posts.isEmpty {
                        ProgressView("Lade Posts...")
                            .tint(theme.current.cAccent)
                            .foregroundColor(theme.current.cMuted)
                            .padding(.top, 40)
                    } else if fetcher.posts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundColor(theme.current.cMuted)
                            Text("Keine Ergebnisse gefunden")
                                .foregroundColor(theme.current.cMuted)
                        }
                        .padding(.top, 60)
                    } else {
                        MasonryGrid(posts: fetcher.posts, namespace: animationNamespace) { post in
                            selectedPost = post
                            showViewer = true
                        }
                        
                        // NEU: Infinite Scroll (Load More)
                        if fetcher.canLoadMore {
                            ProgressView()
                                .tint(theme.current.cAccent)
                                .padding(.vertical, 30)
                                .onAppear {
                                    Task { await fetcher.fetch(tags: searchText) }
                                }
                        }
                    }
                }
            }
            // NEU: Pull-to-Refresh
            .refreshable {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                await fetcher.fetch(tags: searchText, reset: true)
            }
            
            // Viewer Overlay
            if showViewer, let post = selectedPost {
                Viewer(post: post, namespace: animationNamespace, isPresented: $showViewer)
                    .zIndex(2)
            }
        }
        .task {
            if fetcher.posts.isEmpty {
                await fetcher.fetch(reset: true)
            }
        }
        // NEU: Filter-Menü als Bottom Sheet
        .sheet(isPresented: $showFilters) {
            FilterSheetView(searchText: $searchText) {
                Task { await fetcher.fetch(tags: searchText, reset: true) }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: settings.activeAccountId) { oldId, newId in
            Task { await fetcher.fetch(tags: searchText, reset: true) }
        }
    }
}

// MARK: - Filter Sheet
struct FilterSheetView: View {
    @ObservedObject var theme = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    @Binding var searchText: String
    var onApply: () -> Void
    
    // Einfache Filter-Optionen für das UI
    @State private var selectedRating = "All"
    let ratings = ["All", "Safe", "Questionable", "Explicit"]
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.current.cBgMain.ignoresSafeArea()
                
                Form {
                    Section(header: Text("Rating").foregroundColor(theme.current.cMuted)) {
                        Picker("Rating", selection: $selectedRating) {
                            ForEach(ratings, id: \.self) {
                                Text($0).foregroundColor(theme.current.cTextMain)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(theme.current.cBgSub)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Anwenden") {
                        // Hier bauen wir später die Logik ein, um 'rating:safe' an die Suchleiste anzuhängen
                        dismiss()
                        onApply()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(theme.current.cAccent)
                }
            }
        }
        .presentationDetents([.medium]) // Macht das Sheet nur halb hoch!
    }
}

// MARK: - Subviews

struct HeaderArea: View {
    @ObservedObject var theme = ThemeManager.shared
    var onSettings: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bento")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(theme.current.cTextMain)
                Text("Explore the collection")
                    .font(.subheadline)
                    .foregroundColor(theme.current.cMuted)
            }
            Spacer()
            
            Button(action: onSettings) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title)
                    .foregroundColor(theme.current.cMuted)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

struct SearchArea: View {
    @ObservedObject var theme = ThemeManager.shared
    @Binding var text: String
    @Binding var isExpanded: Bool
    var onCommit: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.current.cMuted)
            
            TextField("Search tags...", text: $text)
                .foregroundColor(theme.current.cTextMain)
                .submitLabel(.search)
                .onSubmit(onCommit)
            
            if !text.isEmpty {
                Button {
                    text = ""
                    onCommit()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.current.cMuted)
                }
            }
        }
        .padding(12)
        .background(theme.current.cBgSub)
        .cornerRadius(15)
        .padding(.leading, 16) // Angepasst wegen dem Filter-Button
    }
}

struct HeroSection: View {
    @ObservedObject var theme = ThemeManager.shared
    let post: Post
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: post.previewUrl) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(theme.current.cBgSub)
            }
            .frame(height: 250)
            .clipped()
            .cornerRadius(16)
            
            // Gradient Overlay
            LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .bottom, endPoint: .center)
                .cornerRadius(16)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("NEWEST POST")
                    .font(.caption.bold())
                    .foregroundColor(theme.current.cAccent)
                Text(post.artistName)
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            .padding(16)
        }
        .padding(.horizontal)
    }
}

// MARK: - Masonry Grid & Grid Cell

struct MasonryGrid: View {
    let posts: [Post]
    var namespace: Namespace.ID
    var onSelect: (Post) -> Void
    
    var columns: ([Post], [Post]) {
        var left: [Post] = []
        var right: [Post] = []
        
        for (index, post) in posts.enumerated() {
            if index % 2 == 0 { left.append(post) } else { right.append(post) }
        }
        return (left, right)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            LazyVStack(spacing: 10) {
                ForEach(columns.0) { post in
                    GridCell(post: post, namespace: namespace)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                onSelect(post)
                            }
                        }
                }
            }
            
            LazyVStack(spacing: 10) {
                ForEach(columns.1) { post in
                    GridCell(post: post, namespace: namespace)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                onSelect(post)
                            }
                        }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct GridCell: View {
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var settings = SettingsStore.shared
    let post: Post
    var namespace: Namespace.ID
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            let isGif = post.file.ext?.lowercased() == "gif"
            
            // NEU: Safe Mode Check
            // Wenn safeMode an ist und das Bild nicht "s" (safe) ist, wird zensiert
            let isCensored = settings.safeMode && (post.rating != "s")
            
            if isGif, let urlString = post.file.url, let url = URL(string: urlString) {
                GIFPlayerView(url: url)
                    .aspectRatio(post.aspectRatio, contentMode: .fit)
                    .blur(radius: isCensored ? 20 : 0) // Zensur anwenden
                    .matchedGeometryEffect(id: "image-\(post.id)", in: namespace)
            } else {
                AsyncImage(url: post.previewUrl) { image in
                    image.resizable()
                        .aspectRatio(post.aspectRatio, contentMode: .fit)
                        .blur(radius: isCensored ? 20 : 0) // Zensur anwenden
                        .matchedGeometryEffect(id: "image-\(post.id)", in: namespace)
                } placeholder: {
                    Rectangle()
                        .fill(theme.current.cBgSub)
                        .aspectRatio(post.aspectRatio, contentMode: .fit)
                }
            }
            
            // Censor Icon Overlay
            if isCensored {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "eye.slash.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                    Spacer()
                }
            }
            
            // Bottom Bar
            HStack {
                Text(post.artistName)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(.black.opacity(0.5))
                    .cornerRadius(4)
                
                Spacer()
                
                if let ext = post.file.ext, ["mp4", "webm", "gif"].contains(ext.lowercased()) {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                }
            }
            .padding(6)
        }
        .cornerRadius(12)
        .clipped()
    }
}