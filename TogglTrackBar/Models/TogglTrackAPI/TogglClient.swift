import Foundation

struct TogglClient: Codable, Identifiable {
    let id: Int
    let name: String
    let wid: Int
    let archived: Bool
    let modifiedAt: String
    let creatorId: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, name, wid, archived, notes
        case modifiedAt = "at"
        case creatorId = "creator_id"
    }
}
