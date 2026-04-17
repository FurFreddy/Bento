import SwiftUI

// --- Models for Account Management ---

struct Account: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var type: String
    var domain: String
    var username: String = ""
    var apiKey: String = ""
    var botCheckPassed: Bool = false
    
    // Layout Overrides
    var homeHeroTypeOverride: String? = "global"
    var homeScrollerTypeOverride: String? = "global"
    var homeTimelineTypeOverride: String? = "global"
}

struct BooruTemplate: Identifiable {
    let id: String
    let name: String
    let type: String
    let domain: String
}

let BOORU_TEMPLATES = [
    BooruTemplate(id: "atf", name: "AllTheFallen", type: "danbooru", domain: "https://booru.allthefallen.moe"),
    BooruTemplate(id: "danbooru", name: "Danbooru", type: "danbooru", domain: "https://danbooru.donmai.us"),
    BooruTemplate(id: "gelbooru", name: "Gelbooru", type: "gelbooru", domain: "https://gelbooru.com"),
    BooruTemplate(id: "e621", name: "e621", type: "e621", domain: "https://e621.net"),
    BooruTemplate(id: "rule34", name: "Rule34", type: "gelbooru", domain: "https://rule34.xxx"),
    BooruTemplate(id: "konachan", name: "Konachan", type: "moebooru", domain: "https://konachan.com")
]

// --- Existing e621 Models ---

struct E621Response: Codable {
    let posts: [Post]
}

struct Post: Identifiable, Codable {
    let id: Int
    let file: FileData
    let sample: SampleData
    let tags: TagData
    let description: String?
    let rating: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, file, sample, tags, description, rating
        case createdAt = "created_at"
    }
    
    struct FileData: Codable {
        let width: Int
        let height: Int
        let ext: String?
        let url: String?
        let size: Int?
    }
    
    struct SampleData: Codable {
        let url: String?
    }
    
    struct TagData: Codable {
        let general: [String]
        let artist: [String]?
        let copyright: [String]?
        let character: [String]?
        let species: [String]?
        let meta: [String]?
    }
    
    var previewUrl: URL? {
        if let urlString = sample.url ?? file.url {
            return URL(string: urlString)
        }
        return nil
    }
    
    var aspectRatio: CGFloat {
        CGFloat(file.width) / CGFloat(max(1, file.height))
    }
    
    var artistName: String {
        tags.artist?.first?.capitalized ?? "Unknown Artist"
    }
    
    var tagCategories: [(name: String, tags: [String], category: String)] {
        var cats: [(name: String, tags: [String], category: String)] = []
        if let artist = tags.artist, !artist.isEmpty { cats.append(("Artist", artist, "artist")) }
        if let char = tags.character, !char.isEmpty { cats.append(("Character", char, "character")) }
        if let copy = tags.copyright, !copy.isEmpty { cats.append(("Copyright", copy, "copyright")) }
        if let spec = tags.species, !spec.isEmpty { cats.append(("Species", spec, "species")) }
        if !tags.general.isEmpty { cats.append(("General", tags.general, "general")) }
        if let meta = tags.meta, !meta.isEmpty { cats.append(("Meta", meta, "meta")) }
        return cats
    }
}
