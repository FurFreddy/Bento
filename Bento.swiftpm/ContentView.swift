import SwiftUI

struct ContentView: View {
    @StateObject private var fetcher = PostFetcher()
    @State private var searchText = ""
    @Namespace private var animationNamespace
    
    @State private var selectedPost: Post?
    @State private var showViewer = false
    
    var body: some View {
        ZStack {
            // Main Content
            NavigationView {
                ZStack {
                    Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header
                            HeaderView()
                            
                            // Search Bar
                            SearchBar(text: $searchText) {
                                Task { await fetcher.fetch(tags: searchText, reset: true) }
                            }
                            
                            // Grid
                            if fetcher.posts.isEmpty && fetcher.isLoading {
                                LoadingStateView()
                            } else {
                                MasonryGrid(posts: fetcher.posts, namespace: animationNamespace) { post in
                                    selectedPost = post
                                    showViewer = true
                                }
                                
                                // Load More Trigger
                                if fetcher.canLoadMore {
                                    ProgressView()
                                        .onAppear {
                                            Task { await fetcher.fetch(tags: searchText) }
                                        }
                                        .padding()
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                .navigationBarHidden(true)
            }
            .navigationViewStyle(.stack)
            
            // Viewer Overlay
            if showViewer, let post = selectedPost {
                MediaViewer(post: post, namespace: animationNamespace, isPresented: $showViewer)
                    .zIndex(2)
            }
        }
        .task {
            if fetcher.posts.isEmpty {
                await fetcher.fetch(reset: true)
            }
        }
    }
}

// MARK: - Subviews
struct HeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bento")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("Explore the collection")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            Button {
                // Settings or Profile
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

struct SearchBar: View {
    @Binding var text: String
    var onCommit: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search tags...", text: $text)
                .textFieldStyle(.plain)
                .submitLabel(.search)
                .onSubmit(onCommit)
            
            if !text.isEmpty {
                Button {
                    text = ""
                    onCommit()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Gathering inspiration...")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }
}

#Preview {
    ContentView()
}
