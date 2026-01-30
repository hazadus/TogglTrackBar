import Foundation

struct TogglProject: Codable, Identifiable {
    let id: Int
    let workspaceId: Int
    let name: String
    let active: Bool
    let billable: Bool?
    let isPrivate: Bool
    let color: String
    let createdAt: String
    let modifiedAt: String
    let startDate: String
    let endDate: String?
    let clientId: Int?
    let clientName: String?
    let actualHours: Int?
    let actualSeconds: Int?
    let estimatedHours: Int?
    let estimatedSeconds: Int?
    let rate: Double?
    let rateLastUpdated: String?
    let fixedFee: Double?
    let currency: String?
    let recurring: Bool?
    let template: Bool?
    let templateId: Int?
    let autoEstimates: Bool?
    let canTrackTime: Bool?
    let pinned: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, active, billable, color, rate, currency, recurring, template, pinned
        case modifiedAt = "at"
        case workspaceId = "workspace_id"
        case isPrivate = "is_private"
        case createdAt = "created_at"
        case startDate = "start_date"
        case endDate = "end_date"
        case clientId = "client_id"
        case clientName = "client_name"
        case actualHours = "actual_hours"
        case actualSeconds = "actual_seconds"
        case estimatedHours = "estimated_hours"
        case estimatedSeconds = "estimated_seconds"
        case rateLastUpdated = "rate_last_updated"
        case fixedFee = "fixed_fee"
        case templateId = "template_id"
        case autoEstimates = "auto_estimates"
        case canTrackTime = "can_track_time"
    }
}
