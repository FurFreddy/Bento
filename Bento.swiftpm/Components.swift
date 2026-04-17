import SwiftUI

// MARK: - Post Cell
struct PostCell: View {
    let post: Post
    var namespace: Namespace.ID
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: post.previewUrl) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.1)
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .matchedGeometryEffect(id: "image-\(post.id)", in: namespace)
                case .failure:
                    ZStack {
                        Color.red.opacity(0.1)
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red.opacity(0.5))
                    }
                @unknown default:
                    EmptyView()
                }
            }
            
            // Subtle Overlay for Artist Name
            LinearGradient(colors: [.black.opacity(0.7), .clear], startPoint: .bottom, endPoint: .center)
                .frame(height: 40)
            
            Text(post.artistName)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(8)
                .lineLimit(1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Masonry Grid
struct MasonryGrid: View {
    let posts: [Post]
    var namespace: Namespace.ID
    let onSelect: (Post) -> Void
    
    // Split posts into two columns
    var columns: ([Post], [Post]) {
        var left: [Post] = []
        var right: [Post] = []
        
        // Simple alternating split
        for (index, post) in posts.enumerated() {
            if index % 2 == 0 {
                left.append(post)
            } else {
                right.append(post)
            }
        }
        return (left, right)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            LazyVStack(spacing: 12) {
                ForEach(columns.0) { post in
                    PostCell(post: post, namespace: namespace)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                onSelect(post)
                            }
                        }
                }
            }
            
            LazyVStack(spacing: 12) {
                ForEach(columns.1) { post in
                    PostCell(post: post, namespace: namespace)
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
