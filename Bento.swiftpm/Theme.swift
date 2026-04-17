import SwiftUI

struct AppTheme: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    
    // Core Colors (Hex Strings)
    var bgMain: String
    var bgSub: String
    var muted: String
    var accent: String
    var textMain: String
    
    // Tag Colors (Optional Overrides)
    var tagArtist: String?
    var tagCopyright: String?
    var tagCharacter: String?
    var tagSpecies: String?
    var tagGeneral: String?
    var tagMeta: String?
    
    // SwiftUI Color helpers
    var cBgMain: Color { Color(hex: bgMain) }
    var cBgSub: Color { Color(hex: bgSub) }
    var cMuted: Color { Color(hex: muted) }
    var cAccent: Color { Color(hex: accent) }
    var cTextMain: Color { Color(hex: textMain) }
    
    func colorForTag(category: String) -> Color {
        switch category {
        case "artist": return Color(hex: tagArtist ?? accent)
        case "copyright": return Color(hex: tagCopyright ?? textMain)
        case "character": return Color(hex: tagCharacter ?? textMain)
        case "species": return Color(hex: tagSpecies ?? textMain)
        case "general": return Color(hex: tagGeneral ?? accent)
        default: return Color(hex: tagMeta ?? muted)
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @AppStorage("selected_theme_id") var selectedThemeId: String = "default"
    @Published var current: AppTheme
    
    var baseThemes: [AppTheme] {
        allThemes.filter { ["default", "e621", "cyberpunk", "dracula", "nord"].contains($0.id) }
    }
    
    var prideThemes: [AppTheme] {
        allThemes.filter { !["default", "e621", "cyberpunk", "dracula", "nord"].contains($0.id) }
    }
    
    let allThemes: [AppTheme] = [
        AppTheme(
            id: "default",
            name: "Default",
            bgMain: "#3D1F2B",
            bgSub: "#4E2A3A",
            muted: "#8B6070",
            accent: "#FFB8C5",
            textMain: "#FFFFFF"
        ),
        AppTheme(
            id: "e621",
            name: "e621",
            bgMain: "#001a35",
            bgSub: "#00254a",
            muted: "#014995",
            accent: "#fcb328",
            textMain: "#ffffff"
        ),
        AppTheme(
            id: "cyberpunk",
            name: "Cyberpunk",
            bgMain: "#12121a",
            bgSub: "#1e1f2e",
            muted: "#4a5270",
            accent: "#00c2cb",
            textMain: "#e0e4f5"
        ),
        AppTheme(
            id: "dracula",
            name: "Dracula",
            bgMain: "#282a36",
            bgSub: "#44475a",
            muted: "#6272a4",
            accent: "#ff79c6",
            textMain: "#f8f8f2"
        ),
        AppTheme(
            id: "nord",
            name: "Nord",
            bgMain: "#2e3440",
            bgSub: "#3b4252",
            muted: "#4c566a",
            accent: "#88c0d0",
            textMain: "#eceff4"
        ),
        AppTheme(
            id: "trans",
            name: "Trans",
            bgMain: "#244B78",
            bgSub: "#366194",
            muted: "#7CA8D4",
            accent: "#f5a9b8",
            textMain: "#F0F5FA"
        ),
        AppTheme(
            id: "bi",
            name: "Bi",
            bgMain: "#1f1526",
            bgSub: "#31223d",
            muted: "#7d5e96",
            accent: "#d65ca1",
            textMain: "#e8e3eb"
        ),
        AppTheme(
            id: "lesbian",
            name: "Lesbian",
            bgMain: "#291518",
            bgSub: "#3d2024",
            muted: "#ba6898",
            accent: "#d9825b",
            textMain: "#f2e6eb"
        ),
        AppTheme(
            id: "pan",
            name: "Pan",
            bgMain: "#291522",
            bgSub: "#3b1f32",
            muted: "#67a0d6",
            accent: "#d4c257",
            textMain: "#f0f4f5"
        ),
        AppTheme(
            id: "non_binary",
            name: "Non-Binary",
            bgMain: "#1e1c24",
            bgSub: "#2d2b36",
            muted: "#7f7b8c",
            accent: "#e3c94b",
            textMain: "#e8e6eb"
        ),
        AppTheme(
            id: "ace",
            name: "Ace",
            bgMain: "#1a1a1e",
            bgSub: "#2a2a30",
            muted: "#737380",
            accent: "#a27db3",
            textMain: "#e5e5e5"
        ),
        AppTheme(
            id: "aro",
            name: "Aro",
            bgMain: "#172119",
            bgSub: "#253629",
            muted: "#6b8e73",
            accent: "#7dc48a",
            textMain: "#e3ede5"
        ),
        AppTheme(
            id: "zoo",
            name: "Zoo",
            bgMain: "#1A1514",
            bgSub: "#26201E",
            muted: "#738A81",
            accent: "#5C9E8B",
            textMain: "#E3DDD9"
        ),
        AppTheme(
            id: "map",
            name: "Map",
            bgMain: "#2A527A",
            bgSub: "#386694",
            muted: "#93D1E5",
            accent: "#F1A4BA",
            textMain: "#F5F3A1"
        )
    ]
    
    init() {
        let id = UserDefaults.standard.string(forKey: "selected_theme_id") ?? "default"
        // Setup initial theme by searching the list
        self.current = [
            AppTheme(id: "default", name: "Default", bgMain: "#3D1F2B", bgSub: "#4E2A3A", muted: "#8B6070", accent: "#FFB8C5", textMain: "#FFFFFF"),
            AppTheme(id: "e621", name: "e621", bgMain: "#001a35", bgSub: "#00254a", muted: "#014995", accent: "#fcb328", textMain: "#ffffff"),
            AppTheme(id: "cyberpunk", name: "Cyberpunk", bgMain: "#12121a", bgSub: "#1e1f2e", muted: "#4a5270", accent: "#00c2cb", textMain: "#e0e4f5"),
            AppTheme(id: "dracula", name: "Dracula", bgMain: "#282a36", bgSub: "#44475a", muted: "#6272a4", accent: "#ff79c6", textMain: "#f8f8f2"),
            AppTheme(id: "nord", name: "Nord", bgMain: "#2e3440", bgSub: "#3b4252", muted: "#4c566a", accent: "#88c0d0", textMain: "#eceff4"),
            AppTheme(id: "trans", name: "Trans", bgMain: "#244B78", bgSub: "#366194", muted: "#7CA8D4", accent: "#f5a9b8", textMain: "#F0F5FA"),
            AppTheme(id: "bi", name: "Bi", bgMain: "#1f1526", bgSub: "#31223d", muted: "#7d5e96", accent: "#d65ca1", textMain: "#e8e3eb"),
            AppTheme(id: "lesbian", name: "Lesbian", bgMain: "#291518", bgSub: "#3d2024", muted: "#ba6898", accent: "#d9825b", textMain: "#f2e6eb"),
            AppTheme(id: "pan", name: "Pan", bgMain: "#291522", bgSub: "#3b1f32", muted: "#67a0d6", accent: "#d4c257", textMain: "#f0f4f5"),
            AppTheme(id: "non_binary", name: "Non-Binary", bgMain: "#1e1c24", bgSub: "#2d2b36", muted: "#7f7b8c", accent: "#e3c94b", textMain: "#e8e6eb"),
            AppTheme(id: "ace", name: "Ace", bgMain: "#1a1a1e", bgSub: "#2a2a30", muted: "#737380", accent: "#a27db3", textMain: "#e5e5e5"),
            AppTheme(id: "aro", name: "Aro", bgMain: "#172119", bgSub: "#253629", muted: "#6b8e73", accent: "#7dc48a", textMain: "#e3ede5"),
            AppTheme(id: "zoo", name: "Zoo", bgMain: "#1A1514", bgSub: "#26201E", muted: "#738A81", accent: "#5C9E8B", textMain: "#E3DDD9"),
            AppTheme(id: "map", name: "Map", bgMain: "#2A527A", bgSub: "#386694", muted: "#93D1E5", accent: "#F1A4BA", textMain: "#F5F3A1")
        ].first(where: { $0.id == id }) ?? AppTheme(id: "default", name: "Default", bgMain: "#3D1F2B", bgSub: "#4E2A3A", muted: "#8B6070", accent: "#FFB8C5", textMain: "#FFFFFF")
    }
    
    func setTheme(_ theme: AppTheme) {
        selectedThemeId = theme.id
        current = theme
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
