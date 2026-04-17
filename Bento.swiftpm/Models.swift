import SwiftUI

struct E621Response: Codable {
    let posts: [Post]
}

struct Post: Identifiable, Codable {
    let id: Int
    let file: FileData
    let sample: SampleData
    let tags: TagData
    let description: String?
    
    struct FileData: Codable {
        let width: Int
        let height: Int
        let ext: String?
        let url: String?
    }
    
    struct SampleData: Codable {
        let width: Int?
        let height: Int?
        let url: String?
    }
    
    struct TagData: Codable {
        let general: [String]
        let artist: [String]?
    }
    
    var previewUrl: URL? {
        if let urlString = sample.url ?? file.url {
            return URL(string: urlString)
        }
        return nil
    }
    
    var aspectRatio: CGFloat {
        CGFloat(file.width) / CGFloat(file.height)
    }
    
    var artistName: String {
        tags.artist?.first?.capitalized ?? "Unknown Artist"
    }
}
