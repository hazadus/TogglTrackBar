import Foundation

struct TogglTag: Codable, Identifiable {
    let id: Int
    let name: String
    let workspaceId: Int
    let modifiedAt: String
    let creatorId: Int?
    let deletedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case modifiedAt = "at"
        case workspaceId = "workspace_id"
        case creatorId = "creator_id"
        case deletedAt = "deleted_at"
    }
}
