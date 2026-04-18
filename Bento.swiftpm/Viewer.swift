import SwiftUI
import UIKit
import WebKit

struct Viewer: View {
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var settings = SettingsStore.shared
    let post: Post
    var namespace: Namespace.ID
    @Binding var isPresented: Bool
    
    @State private var dragOffset: CGSize = .zero
    @State private var backgroundOpacity: Double = 1.0
    @State private var isFavorited: Bool = false
    @State private var currentScore: Int = 0
    
    var body: some View {
        ZStack {
            // Hintergrund
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
            
            // Die ScrollView für den gesamten Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    // --- MEDIA SEKTION ---
                    // Hier liegt die Geste zum Schließen
                    ZStack(alignment: .topTrailing) {
                        MediaDisplay(post: post, namespace: namespace)
                            .offset(dragOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        // Nur reagieren, wenn nach unten gewischt wird
                                        if value.translation.height > 0 {
                                            dragOffset = value.translation
                                            backgroundOpacity = max(0.5, 1.0 - Double(dragOffset.height) / 800.0)
                                        }
                                    }
                                    .onEnded { value in
                                        if value.translation.height > 120 {
                                            dismiss()
                                        } else {
                                            withAnimation(.interactiveSpring()) {
                                                dragOffset = .zero
                                                backgroundOpacity = 1.0
                                            }
                                        }
                                    }
                            )
                        
                        // Close Button
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(20)
                        }
                    }
                    
                    // --- INFO & AKTION SEKTION ---
                    VStack(alignment: .leading, spacing: 25) {
                        
                        // Action Bar (Like, Vote, Download)
                        HStack(spacing: 25) {
                            // Upvote
                            VStack(spacing: 4) {
                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    currentScore += 1
                                } label: {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(theme.current.cAccent)
                                }
                                Text("\(currentScore)")
                                    .font(.caption2.bold())
                                    .foregroundColor(theme.current.cTextMain)
                            }
                            
                            // Favorite
                            ActionButton(
                                icon: isFavorited ? "heart.fill" : "heart",
                                label: "Fav",
                                color: isFavorited ? .red : theme.current.cAccent
                            ) {
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                isFavorited.toggle()
                            }
                            
                            ActionButton(icon: "arrow.down.circle", label: "Save") {
                                // Download Logik
                            }
                            
                            ActionButton(icon: "safari", label: "Browser") {
                                if let url = URL(string: "https://e621.net/posts/\(post.id)") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.top, 10)
                        
                        // TAGS NACH KATEGORIEN
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(post.tagCategories, id: \.name) { category in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(category.name.uppercased())
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(theme.current.colorForTag(category: category.category))
                                    
                                    FlowLayout(spacing: 8) {
                                        ForEach(category.tags, id: \.self) { tag in
                                            TagChip(tag: tag, category: category.category)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // INFO CARD
                        VStack(alignment: .leading, spacing: 12) {
                            Text("STATISTICS")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(theme.current.cMuted)
                            
                            InfoCard(post: post)
                        }
                        
                        // SOURCE SECTION
                        if let source = post.description, !source.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("DESCRIPTION / SOURCE")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(theme.current.cMuted)
                                
                                Text(source)
                                    .font(.footnote)
                                    .foregroundColor(theme.current.cTextMain)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(theme.current.cBgSub)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(24)
                    .background(theme.current.cBgMain)
                    .cornerRadius(30, corners: [.topLeft, .topRight])
                    // Sorgt dafür, dass der Hintergrund mitgleitet beim Swipen
                    .offset(y: dragOffset.height > 0 ? dragOffset.height * 0.5 : 0)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            currentScore = post.id % 100 // Beispiel-Score
            isFavorited = false
        }
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            isPresented = false
        }
    }
}

// MARK: - Hilfs-Komponenten

struct MediaDisplay: View {
    let post: Post
    var namespace: Namespace.ID
    
    var body: some View {
        let ext = post.file.ext?.lowercased() ?? ""
        let isVideo = ["mp4", "webm", "mov"].contains(ext)
        let isGif = ext == "gif"
        
        Group {
            if isVideo, let urlString = post.file.url, let url = URL(string: urlString) {
                VideoPlayerView(url: url)
                    .aspectRatio(post.aspectRatio, contentMode: .fit)
            } else if isGif, let urlString = post.file.url, let url = URL(string: urlString) {
                GIFPlayerView(url: url)
                    .aspectRatio(post.aspectRatio, contentMode: .fit)
            } else {
                AsyncImage(url: URL(string: post.file.url ?? "")) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
            }
        }
        .matchedGeometryEffect(id: "image-\(post.id)", in: namespace)
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }
}

struct TagChip: View {
    @ObservedObject var theme = ThemeManager.shared
    let tag: String
    let category: String
    
    var body: some View {
        Text(tag.replacingOccurrences(of: "_", with: " "))
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(theme.current.colorForTag(category: category))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(theme.current.colorForTag(category: category).opacity(0.12))
            .cornerRadius(10)
            // NEU: Kontext-Menü wie in JS
            .contextMenu {
                Button {
                    UIPasteboard.general.string = tag
                } label: {
                    Label("Copy Tag", systemImage: "doc.on.doc")
                }
                
                Button {
                    // Suche nach diesem Tag starten
                } label: {
                    Label("Search this Tag", systemImage: "magnifyingglass")
                }
                
                Divider()
                
                Button(role: .destructive) {
                    // Blacklist Logik
                } label: {
                    Label("Add to Blacklist", systemImage: "eye.slash")
                }
            }
    }
}

struct ActionButton: View {
    @ObservedObject var theme = ThemeManager.shared
    let icon: String
    let label: String
    var color: Color? = nil
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.system(size: 10, weight: .black))
            }
            .foregroundColor(color ?? theme.current.cAccent)
            .frame(width: 50)
        }
    }
}