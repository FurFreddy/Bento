import SwiftUI

struct MediaViewer: View {
    let post: Post
    var namespace: Namespace.ID
    @Binding var isPresented: Bool
    
    @State private var dragOffset: CGSize = .zero
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background Blur
            Color.black
                .opacity(opacity)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            VStack {
                // Top Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.artistName)
                            .font(.headline)
                        Text("#\(post.id)")
                            .font(.caption)
                            .opacity(0.7)
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
                .background(
                    LinearGradient(colors: [.black.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom)
                )
                
                Spacer()
                
                // Image
                AsyncImage(url: URL(string: post.file.url ?? "")) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .matchedGeometryEffect(id: "image-\(post.id)", in: namespace)
                            .offset(dragOffset)
                            .scaleEffect(scale)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        dragOffset = value.translation
                                        let dragProgress = Double(abs(value.translation.height) / 300)
                                        opacity = max(0.4, 1.0 - dragProgress)
                                        scale = max(0.8, 1.0 - dragProgress * 0.5)
                                    }
                                    .onEnded { value in
                                        if abs(value.translation.height) > 100 {
                                            dismiss()
                                        } else {
                                            withAnimation(.interactiveSpring()) {
                                                dragOffset = .zero
                                                opacity = 1.0
                                                scale = 1.0
                                            }
                                        }
                                    }
                            )
                    case .failure:
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                
                Spacer()
                
                // Bottom Info/Actions
                if let desc = post.description, !desc.isEmpty {
                    ScrollView {
                        Text(desc)
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .frame(maxHeight: 150)
                    .background(.black.opacity(0.4))
                }
            }
        }
        .transition(.asymmetric(insertion: .identity, removal: .opacity))
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            isPresented = false
        }
    }
}
