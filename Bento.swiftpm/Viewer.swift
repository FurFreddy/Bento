import SwiftUI

struct Viewer: View {
    @ObservedObject var theme = ThemeManager.shared
    let post: Post
    var namespace: Namespace.ID
    @Binding var isPresented: Bool
    
    @State private var dragOffset: CGSize = .zero
    @State private var backgroundOpacity: Double = 1.0
    
    var body: some View {
        ZStack {
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // IMAGE / VIDEO / GIF SECTION
                    ZStack(alignment: .topTrailing) {
                        let ext = post.file.ext?.lowercased() ?? ""
                        let isVideo = ["mp4", "webm", "mov", "m4v"].contains(ext)
                        let isGif = ext == "gif"
                        
                        if isVideo, let urlString = post.file.url, let url = URL(string: urlString) {
                            VideoPlayerView(url: url)
                                .aspectRatio(post.aspectRatio, contentMode: .fit)
                                .matchedGeometryEffect(id: "image-\(post.id)", in: namespace)
                        } else if isGif, let urlString = post.file.url, let url = URL(string: urlString) {
                            GIFPlayerView(url: url)
                                .aspectRatio(post.aspectRatio, contentMode: .fit)
                                .matchedGeometryEffect(id: "image-\(post.id)", in: namespace)
                        } else {
                            AsyncImage(url: URL(string: post.file.url ?? "")) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .matchedGeometryEffect(id: "image-\(post.id)", in: namespace)
                            } placeholder: {
                                ProgressView().tint(theme.current.cAccent)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .offset(dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation
                                    backgroundOpacity = max(0.5, 1.0 - abs(dragOffset.height) / 500)
                                }
                                .onEnded { value in
                                    if abs(dragOffset.height) > 100 {
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
                                .font(.title)
                                .foregroundColor(.white.opacity(0.7))
                                .padding()
                        }
                    }
                    
                    // CONTENT SECTION
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Action Buttons (Favorite, Download etc - placeholders)
                        HStack(spacing: 20) {
                            ActionButton(icon: "heart", label: "Favorite")
                            ActionButton(icon: "arrow.down.circle", label: "Save")
                            ActionButton(icon: "square.and.arrow.up", label: "Share")
                            Spacer()
                        }
                        .padding(.top, 10)
                        
                        // TAGS CATEGORIES
                        Text("TAGS")
                            .font(.caption.bold())
                            .foregroundColor(theme.current.cMuted)
                        
                        ForEach(post.tagCategories, id: \.name) { category in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(category.name.uppercased())
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(theme.current.colorForTag(category: category.category))
                                    .padding(.bottom, 2)
                                
                                FlowLayout(spacing: 6) {
                                    ForEach(category.tags, id: \.self) { tag in
                                        TagChip(tag: tag, category: category.category)
                                    }
                                }
                            }
                        }
                        
                        // INFO SECTION
                        Text("INFO")
                            .font(.caption.bold())
                            .foregroundColor(theme.current.cMuted)
                            .padding(.top, 10)
                        
                        InfoCard(post: post)
                        
                    }
                    .padding(20)
                    .background(theme.current.cBgMain)
                    .cornerRadius(25, corners: [.topLeft, .topRight])
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .transition(.opacity)
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            isPresented = false
        }
    }
}

// MARK: - Subviews
struct TagChip: View {
    @ObservedObject var theme = ThemeManager.shared
    let tag: String
    let category: String
    
    var body: some View {
        Text(tag.replacingOccurrences(of: "_", with: " "))
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(theme.current.colorForTag(category: category))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(theme.current.colorForTag(category: category).opacity(0.15))
            .cornerRadius(8)
    }
}

struct InfoCard: View {
    @ObservedObject var theme = ThemeManager.shared
    let post: Post
    var body: some View {
        VStack(spacing: 1) {
            InfoRow(label: "ID", value: "#\(post.id)")
            InfoRow(label: "Rating", value: post.rating?.capitalized ?? "Unknown")
            InfoRow(label: "Created", value: post.createdAt ?? "N/A")
            InfoRow(label: "Format", value: "\(post.file.ext?.uppercased() ?? "??") (\(post.file.width)x\(post.file.height))")
        }
        .background(theme.current.cBgSub)
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    @ObservedObject var theme = ThemeManager.shared
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundColor(theme.current.cMuted)
            Spacer()
            Text(value).foregroundColor(theme.current.cTextMain).bold()
        }
        .font(.system(size: 13))
        .padding(12)
        .background(theme.current.cBgSub)
    }
}

struct ActionButton: View {
    @ObservedObject var theme = ThemeManager.shared
    let icon: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
            Text(label)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(theme.current.cAccent)
    }
}

// MARK: - Subviews shared from Components.swift or localized here
