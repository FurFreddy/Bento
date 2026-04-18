import SwiftUI
import WebKit
import AVKit
import UIKit

// MARK: - Video Player
struct VideoPlayerView: View {
    let url: URL
    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?
    @State private var isMuted: Bool = true
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                        player.isMuted = isMuted
                    }
                    .onDisappear { player.pause() }
            } else {
                ProgressView().onAppear { setupPlayer() }
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        isMuted.toggle()
                        player?.isMuted = isMuted
                    } label: {
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .padding(10)
                            .background(.black.opacity(0.5))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    .padding(20)
                }
            }
        }
        .background(Color.black)
    }
    
    private func setupPlayer() {
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        let playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        
        self.player = queuePlayer
        self.looper = playerLooper
    }
}

// MARK: - GIF Player
struct GIFPlayerView: View {
    let url: URL
    var body: some View {
        GIFWebView(url: url).allowsHitTesting(false)
    }
}

struct GIFWebView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        
        let html = """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body { margin: 0; padding: 0; background: transparent; display: flex; justify-content: center; align-items: center; height: 100vh; overflow: hidden; }
                img { max-width: 100%; max-height: 100%; object-fit: contain; }
            </style>
        </head>
        <body><img src="\(url.absoluteString)"></body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - Theme Components
struct ThemePreview: View {
    let theme: AppTheme
    let isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(theme.cBgMain)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .fill(theme.cAccent)
                    .frame(width: 25, height: 25)
                    .offset(x: 10, y: 10)
            }
            .overlay(
                Circle()
                    .stroke(isSelected ? theme.cAccent : Color.clear, lineWidth: 3)
                    .scaleEffect(1.2)
            )
            
            Text(theme.name)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isSelected ? theme.cAccent : .gray)
        }
        .padding(.vertical, 10)
        .onTapGesture {
            action()
        }
    }
}

// MARK: - Account Management
struct AddAccountView: View {
    @ObservedObject var theme = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            theme.current.cBgMain.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("CHOOSE A TEMPLATE")
                        .font(.caption.bold())
                        .foregroundColor(theme.current.cMuted)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(BOORU_TEMPLATES) { tmpl in
                            Button {
                                let acc = Account(name: tmpl.name, type: tmpl.type, domain: tmpl.domain)
                                SettingsStore.shared.addAccount(acc)
                                dismiss()
                            } label: {
                                VStack(spacing: 8) {
                                    Text(tmpl.name).bold()
                                    Text(tmpl.domain.replacingOccurrences(of: "https://", with: ""))
                                        .font(.caption2)
                                        .opacity(0.7)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(theme.current.cBgSub)
                                .foregroundColor(theme.current.cTextMain)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
    }
}

struct EditAccountView: View {
    @ObservedObject var theme = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    @State var account: Account
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.current.cBgMain.ignoresSafeArea()
                Form {
                    Section("Identity") {
                        TextField("Name", text: $account.name)
                        TextField("Domain", text: $account.domain)
                    }
                    Section("Library") {
                        TextField("Username", text: $account.username)
                        SecureField("API Key / Password", text: $account.apiKey)
                    }
                    
                    Button("Delete Account", role: .destructive) {
                        SettingsStore.shared.deleteAccount(account.id)
                        dismiss()
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Account")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        SettingsStore.shared.updateAccount(account)
                        dismiss()
                    }
                    .foregroundColor(theme.current.cAccent)
                }
            }
        }
    }
}

// MARK: - Data Info Components
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
        .clipped()
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

// MARK: - Layout & Helpers
struct FlowLayout: Layout {
    var spacing: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for element in result.elements {
            element.view.place(at: CGPoint(x: bounds.minX + element.x, y: bounds.minY + element.y), proposal: .unspecified)
        }
    }
    struct FlowResult {
        struct Element { let view: LayoutSubview; let x: CGFloat; let y: CGFloat }
        var elements: [Element] = []
        var size: CGSize = .zero
        init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
            var currentX: CGFloat = 0, currentY: CGFloat = 0, lineHeight: CGFloat = 0
            for view in subviews {
                let s = view.sizeThatFits(.unspecified)
                if currentX + s.width > maxWidth && currentX > 0 {
                    currentX = 0; currentY += lineHeight + spacing; lineHeight = 0
                }
                elements.append(Element(view: view, x: currentX, y: currentY))
                currentX += s.width + spacing; lineHeight = max(lineHeight, s.height)
            }
            size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
