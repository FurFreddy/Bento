import SwiftUI
import UIKit

struct Index: View {
    @StateObject private var fetcher = PostFetcher()
    @ObservedObject var theme = ThemeManager.shared
    @State private var searchText = ""
    @Namespace private var animationNamespace
    
    @State private var selectedPost: Post?
    @State private var showViewer = false
    @State private var showSettings = false
    
    // Animation for search
    @State private var isSearchExpanded = false
    
    var body: some View {
        ZStack {
            theme.current.cBgMain.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header Area
                    HeaderArea(onSettings: { showSettings = true })
                    
                    // Search Bar Area
                    SearchArea(text: $searchText, isExpanded: $isSearchExpanded) {
                        Task { await fetcher.fetch(tags: searchText, reset: true) }
                    }
                    
                    // HERO SECTION (If enabled/loaded)
                    if let first = fetcher.posts.first, searchText.isEmpty {
                        HeroSection(post: first)
                    }
                    
                    // MAIN GRID
                    if fetcher.isLoading && fetcher.posts.isEmpty {
                        ProgressView()
                            .tint(theme.current.cAccent)
                            .padding(.top, 40)
                    } else {
                        MasonryGrid(posts: fetcher.posts, namespace: animationNamespace) { post in
                            selectedPost = post
                            showViewer = true
                        }
                        
                        // Infinity Scroll Trigger
                        if fetcher.canLoadMore {
                            ProgressView()
                                .tint(theme.current.cAccent)
                                .onAppear {
                                    Task { await fetcher.fetch(tags: searchText) }
                                }
                                .padding()
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            .coordinateSpace(name: "scroll")
            
            // Viewer Overlay
            if showViewer, let post = selectedPost {
                Viewer(post: post, namespace: animationNamespace, isPresented: $showViewer)
                    .zIndex(10)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: SettingsStore.shared.activeAccountId) { _ in
            Task { await fetcher.fetch(tags: searchText, reset: true) }
        }
        .task {
            if fetcher.posts.isEmpty {
                await fetcher.fetch(reset: true)
            }
        }
    }
}

// MARK: - Subviews
struct HeaderArea: View {
    @ObservedObject var theme = ThemeManager.shared
    var onSettings: () -> Void
    var body: some View {
        HStack {
            Text("Bento")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(theme.current.cTextMain)
            Spacer()
            Button { onSettings() } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title2)
                    .foregroundColor(theme.current.cAccent)
            }
        }
        .padding(.horizontal, 20)
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
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.current.cMuted)
                
                if isExpanded {
                    TextField("Search...", text: $text)
                        .textFieldStyle(.plain)
                        .foregroundColor(theme.current.cTextMain)
                        .submitLabel(.search)
                        .onSubmit(onCommit)
                        .transition(.opacity)
                }
                
                if !text.isEmpty && isExpanded {
                    Button { text = ""; onCommit() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.current.cMuted)
                    }
                }
            }
            .padding(12)
            .frame(width: isExpanded ? nil : 44, height: 44)
            .background(theme.current.cBgSub)
            .cornerRadius(22)
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded = true
                }
            }
            
            if !isExpanded {
                Spacer()
                Text("Explore")
                    .font(.subheadline.bold())
                    .foregroundColor(theme.current.cMuted)
            }
        }
        .padding(.horizontal, 20)
    }
}

struct HeroSection: View {
    @ObservedObject var theme = ThemeManager.shared
    let post: Post
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TRENDING")
                .font(.caption.bold())
                .foregroundColor(theme.current.cAccent)
                .padding(.horizontal, 20)
            
            AsyncImage(url: post.previewUrl) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                theme.current.cBgSub
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .clipped()
        }
    }
}

// MARK: - Grid Components
struct MasonryGrid: View {
    let posts: [Post]
    var namespace: Namespace.ID
    let onSelect: (Post) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            let cols = splitPosts(posts)
            LazyVStack(spacing: 6) {
                ForEach(cols.0) { post in
                    GridCell(post: post, namespace: namespace)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onSelect(post)
                        }
                }
            }
            LazyVStack(spacing: 6) {
                ForEach(cols.1) { post in
                    GridCell(post: post, namespace: namespace)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onSelect(post)
                        }
                }
            }
        }
        .padding(.horizontal, 6)
    }
    
    private func splitPosts(_ posts: [Post]) -> ([Post], [Post]) {
        var left: [Post] = []
        var right: [Post] = []
        for (idx, post) in posts.enumerated() {
            if idx % 2 == 0 { left.append(post) } else { right.append(post) }
        }
        return (left, right)
    }
}

struct GridCell: View {
    @ObservedObject var theme = ThemeManager.shared
    let post: Post
    var namespace: Namespace.ID
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            let isGif = post.file.ext?.lowercased() == "gif"
            
            if isGif, let urlString = post.file.url, let url = URL(string: urlString) {
                GIFPlayerView(url: url)
                    .aspectRatio(post.aspectRatio, contentMode: .fit)
                    .matchedGeometryEffect(id: "image-\(post.id)", in: namespace)
            } else {
                AsyncImage(url: post.previewUrl) { image in
                    image.resizable()
                        .aspectRatio(post.aspectRatio, contentMode: .fit)
                        .matchedGeometryEffect(id: "image-\(post.id)", in: namespace)
                } placeholder: {
                    Rectangle()
                        .fill(theme.current.cBgSub)
                        .aspectRatio(post.aspectRatio, contentMode: .fit)
                }
            }
            
            Text(post.artistName)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .padding(4)
                .background(.black.opacity(0.4))
                .cornerRadius(4)
                .padding(4)
        }
        .cornerRadius(12)
        .clipped()
    }
}
