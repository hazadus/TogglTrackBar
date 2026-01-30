import Foundation

struct TogglWorkspace: Codable, Identifiable {
    let id: Int
    let name: String
    let organizationId: Int
    let modifiedAt: String
    let premium: Bool
    let businessWs: Bool
    let admin: Bool
    let defaultCurrency: String?
    let defaultHourlyRate: Double?
    let onlyAdminsMayCreateProjects: Bool?
    let onlyAdminsMayCreateTags: Bool?
    let onlyAdminsSeeTeamDashboard: Bool?
    let projectsBillableByDefault: Bool?
    let projectsEnforceBillable: Bool?
    let projectsPrivateByDefault: Bool?
    let reportsCollapse: Bool?
    let icalEnabled: Bool?
    let icalUrl: String?
    let logoUrl: String?
    let lastModified: String?
    let rateLastUpdated: String?
    let hideStartEndTimes: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, premium, admin
        case modifiedAt = "at"
        case organizationId = "organization_id"
        case businessWs = "business_ws"
        case defaultCurrency = "default_currency"
        case defaultHourlyRate = "default_hourly_rate"
        case onlyAdminsMayCreateProjects = "only_admins_may_create_projects"
        case onlyAdminsMayCreateTags = "only_admins_may_create_tags"
        case onlyAdminsSeeTeamDashboard = "only_admins_see_team_dashboard"
        case projectsBillableByDefault = "projects_billable_by_default"
        case projectsEnforceBillable = "projects_enforce_billable"
        case projectsPrivateByDefault = "projects_private_by_default"
        case reportsCollapse = "reports_collapse"
        case icalEnabled = "ical_enabled"
        case icalUrl = "ical_url"
        case logoUrl = "logo_url"
        case lastModified = "last_modified"
        case rateLastUpdated = "rate_last_updated"
        case hideStartEndTimes = "hide_start_end_times"
    }
}
