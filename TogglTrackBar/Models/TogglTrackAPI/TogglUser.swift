import Foundation

struct TogglUser: Codable, Identifiable {
    let id: Int
    let email: String
    let fullname: String
    let timezone: String
    let defaultWorkspaceId: Int
    let beginningOfWeek: Int
    let imageUrl: String
    let createdAt: String
    let updatedAt: String
    let modifiedAt: String
    let countryId: Int?
    let hasPassword: Bool
    let openidEnabled: Bool
    let openidEmail: String?
    let apiToken: String?
    let intercomHash: String?
    let authorizationUpdatedAt: String?
    let oauthProviders: [String]?

    /// Связанные данные (только при запросах с with_related_data=true)
    let clients: [TogglClient]?
    let projects: [TogglProject]?
    let tags: [TogglTag]?
    let tasks: [TogglTask]?
    let timeEntries: [TogglTimeEntry]?
    let workspaces: [TogglWorkspace]?

    // Невозможно использовать "2fa_enabled" как имя переменной в Swift,
    // поэтому переименовываем
    let twoFactorEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case id, email, fullname, timezone, clients, projects, tags, tasks, workspaces
        case modifiedAt = "at"
        case defaultWorkspaceId = "default_workspace_id"
        case beginningOfWeek = "beginning_of_week"
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case countryId = "country_id"
        case hasPassword = "has_password"
        case openidEnabled = "openid_enabled"
        case openidEmail = "openid_email"
        case apiToken = "api_token"
        case intercomHash = "intercom_hash"
        case authorizationUpdatedAt = "authorization_updated_at"
        case oauthProviders = "oauth_providers"
        case timeEntries = "time_entries"
        case twoFactorEnabled = "2fa_enabled"
    }
}
