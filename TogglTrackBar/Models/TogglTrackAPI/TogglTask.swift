import Foundation

struct TogglTask: Codable, Identifiable {
    let id: Int
    let name: String
    let workspaceId: Int
    let projectId: Int
    let active: Bool
    let modifiedAt: String
    let estimatedSeconds: Int?
    let trackedSeconds: Int?
    let recurring: Bool?
    let userId: Int?
    let userName: String?
    let avatarUrl: String?
    let clientId: Int?
    let clientName: String?
    let projectName: String?
    let projectColor: String?
    let projectBillable: Bool?
    let projectIsPrivate: Bool?
    let rate: Double?
    let rateLastUpdated: String?

    enum CodingKeys: String, CodingKey {
        case id, name, active, recurring, rate
        case modifiedAt = "at"
        case workspaceId = "workspace_id"
        case projectId = "project_id"
        case estimatedSeconds = "estimated_seconds"
        case trackedSeconds = "tracked_seconds"
        case userId = "user_id"
        case userName = "user_name"
        case avatarUrl = "avatar_url"
        case clientId = "client_id"
        case clientName = "client_name"
        case projectName = "project_name"
        case projectColor = "project_color"
        case projectBillable = "project_billable"
        case projectIsPrivate = "project_is_private"
        case rateLastUpdated = "rate_last_updated"
    }
}
