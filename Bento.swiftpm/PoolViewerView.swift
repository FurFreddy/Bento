import SwiftUI

struct PoolViewerView: View {
    let pool: Pool
    var namespace: Namespace.ID
    
    @StateObject private var fetcher = PostFetcher()
    @ObservedObject var theme = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPost: Post?
    @State private var showViewer = false
    
    var poolName: String {
        pool.name.replacingOccurrences(of: "_", with: " ")
    }
    
    var body: some View {
        ZStack {
            theme.current.cBgMain.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    if fetcher.isLoading && fetcher.posts.isEmpty {
                        ProgressView("Lade Posts...")
                            .tint(theme.current.cAccent)
                            .padding(.top, 60)
                    } else if fetcher.posts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.largeTitle)
                                .foregroundColor(theme.current.cMuted)
                            Text("Keine Posts im Pool")
                                .foregroundColor(theme.current.cMuted)
                        }
                        .padding(.top, 100)
                    } else {
                        MasonryGrid(posts: fetcher.posts, namespace: namespace) { post in
                            selectedPost = post
                            showViewer = true
                        }
                        .padding(.top, 16)
                        
                        // Infinite Scroll
                        if fetcher.canLoadMore {
                            ProgressView()
                                .tint(theme.current.cAccent)
                                .padding(.vertical, 30)
                                .onAppear {
                                    Task { await fetcher.fetch(tags: "pool:\(pool.id)") }
                                }
                        }
                    }
                }
            }
            .refreshable {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                await fetcher.fetch(tags: "pool:\(pool.id)", reset: true)
            }
            
            // Viewer Overlay
            if showViewer, let post = selectedPost {
                Viewer(post: post, namespace: namespace, isPresented: $showViewer) { newTag in
                    // If they search from a pool viewer, we dismiss it completely and search in the parent index
                    // For now, let's keep it simple: just dismiss Viewer.
                }
                .zIndex(2)
            }
        }
        .navigationTitle(poolName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.current.cBgMain, for: .navigationBar)
        .task {
            if fetcher.posts.isEmpty {
                await fetcher.fetch(tags: "pool:\(pool.id)", reset: true)
            }
        }
    }
}
