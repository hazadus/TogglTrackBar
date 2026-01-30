import Foundation

/// Запись учёта времени (далее в комментариях – запись времени) TogglTrack API.
/// Представляет собой отрезок времени, в течение которого непрерывно производилась работа над задачей
/// по конкретному проекту.
struct TogglTimeEntry: Codable, Identifiable {
    /// Codable = Encodable & Decodable - для JSON сериализации
    /// Identifiable - требует наличия id. Нужен для ForEach — SwiftUI по id понимает, какой элемент изменился
    let id: Int
    let workspaceId: Int
    let projectId: Int?
    let taskId: Int?
    let billable: Bool
    let start: String
    let stop: String?
    let duration: Int
    let description: String?
    let tags: [String]?
    let tagIds: [Int]?
    let duronly: Bool
    let modifiedAt: String
    let serverDeletedAt: String?
    let userId: Int
    let uid: Int
    let wid: Int
    let pid: Int?

    /// Маппинг snake_case JSON → camelCase Swift
    enum CodingKeys: String, CodingKey {
        /// : CodingKey - протокол, говорящий Codable: "используй меня для маппинга JSON-ключей"
        case id, billable, start, stop, duration, description, tags, duronly, uid, wid, pid
        case modifiedAt = "at"
        case workspaceId = "workspace_id"
        case projectId = "project_id"
        case taskId = "task_id"
        case tagIds = "tag_ids"
        case serverDeletedAt = "server_deleted_at"
        case userId = "user_id"
    }

    /// Computed property – вычисляется при первом обращении, не участвует в Codable
    var startDate: Date? {
        Formatters.isoParser.date(from: start)
    }
}

/// Используется для выборки уникальных записей времени по комбинации идентификатора
/// проекта и описания.
struct UniqueTimeEntryKey: Hashable {
    let description: String?
    let projectId: Int?
}
