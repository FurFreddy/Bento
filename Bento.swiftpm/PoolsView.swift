import SwiftUI

struct PoolsView: View {
    @StateObject private var fetcher = PoolFetcher()
    @ObservedObject var theme = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText = ""
    @Namespace private var animationNamespace
    
    // Array of columns for our Grid
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 10)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.current.cBgMain.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(theme.current.cMuted)
                            
                            TextField("Pool suchen...", text: $searchText)
                                .foregroundColor(theme.current.cTextMain)
                                .submitLabel(.search)
                                .onSubmit {
                                    Task { await fetcher.fetch(search: searchText, reset: true) }
                                }
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                    Task { await fetcher.fetch(search: "", reset: true) }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(theme.current.cMuted)
                                }
                            }
                        }
                        .padding(12)
                        .background(theme.current.cBgSub)
                        .cornerRadius(15)
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // GRID
                        if fetcher.isLoading && fetcher.pools.isEmpty {
                            ProgressView("Lade Pools...")
                                .tint(theme.current.cAccent)
                                .padding(.top, 40)
                        } else if fetcher.pools.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "albums")
                                    .font(.largeTitle)
                                    .foregroundColor(theme.current.cMuted)
                                Text("Keine Pools gefunden")
                                    .foregroundColor(theme.current.cMuted)
                            }
                            .padding(.top, 60)
                        } else {
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(fetcher.pools) { pool in
                                    NavigationLink(destination: PoolViewerView(pool: pool, namespace: animationNamespace)) {
                                        PoolCard(pool: pool)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            if fetcher.canLoadMore {
                                ProgressView()
                                    .tint(theme.current.cAccent)
                                    .padding(.vertical, 30)
                                    .onAppear {
                                        Task { await fetcher.fetch(search: searchText) }
                                    }
                            }
                        }
                    }
                }
                .refreshable {
                    await fetcher.fetch(search: searchText, reset: true)
                }
            }
            .navigationTitle("Pools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.current.cBgMain, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(theme.current.cTextMain)
                    }
                }
            }
        }
        .task {
            if fetcher.pools.isEmpty {
                await fetcher.fetch(reset: true)
            }
        }
    }
}

// MARK: - Pool Card
struct PoolCard: View {
    @ObservedObject var theme = ThemeManager.shared
    let pool: Pool
    
    var poolName: String {
        pool.name.replacingOccurrences(of: "_", with: " ")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail Placeholder (would need an extra image fetch, we'll just show an icon for now)
            ZStack {
                Rectangle()
                    .fill(theme.current.cBgSub)
                    .aspectRatio(1.0, contentMode: .fit)
                
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.largeTitle)
                    .foregroundColor(theme.current.cMuted)
                
                VStack {
                    HStack {
                        Spacer()
                        Text("\(pool.postCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                    }
                    Spacer()
                }
                .padding(6)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(poolName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.current.cTextMain)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    
                if let category = pool.category {
                    Text(category.capitalized)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.current.cAccent)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.current.cBgCard)
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.current.cMuted.opacity(0.2), lineWidth: 1)
        )
    }
}
