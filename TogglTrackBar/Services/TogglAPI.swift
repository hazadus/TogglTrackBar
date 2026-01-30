import Combine
import Foundation
import os

/// Инкапсулирует взаимодействие с TogglTrack API.
final class TogglAPI {
    /// final - запрещает наследование. Компилятор делает оптимизации (static dispatch вместо dynamic)

    private let apiKey: String
    private let session: URLSession
    private let baseURL = "https://api.track.toggl.com/api/v9"

    /// CurrentValueSubject — тип из Combine, который хранит текущее значение и позволяет подписчикам получать обновления
    /// <RateLimitInfo?, Never> — дженерик-параметры: тип значения (RateLimitInfo?) и тип ошибки (Never = ошибок не будет)
    /// (nil) — начальное значение
    let rateLimitSubject = CurrentValueSubject<RateLimitInfo?, Never>(nil)

    /// Форматтер даты в строку вида "2006-01-02T15:04:05Z".
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    // MARK: API Methods
    func getMe() async throws -> TogglUser? {
        try await request(
            endpoint: "/me",
            queryItems: [
                URLQueryItem(name: "with_related_data", value: "true")
            ]
        )
    }

    /// Получает текущую запись времени, или nil – если нет текущей записи.
    /// Здесь и далее под "текущей записью времени" понимается запущенная в настоящий момент запись.
    func getCurrentTimeEntry() async throws -> TogglTimeEntry? {
        /// Optional декодируется автоматически, если API возвращает null
        /// В данном случае функция из одной строки, поэтому можно не указывать return
        /// Тип для request выводится из контекста возврата - в данном случае TimeEntry?
        try await request(endpoint: "/me/time_entries/current")
    }

    /// Возвращает все записи времени за указанный диапазон дат.
    func getTimeEntries(startDate: String, endDate: String) async throws -> [TogglTimeEntry] {
        try await request(
            endpoint: "/me/time_entries",
            queryItems: [
                URLQueryItem(name: "start_date", value: startDate),
                URLQueryItem(name: "end_date", value: endDate)
            ]
        )
    }

    /// Останавливает текущую запись времени.
    /// В случае успеха, возвращает полную информацию об этой записи.
    func stopCurrentTimeEntry(workspaceId: Int, timeEntryId: Int) async throws -> TogglTimeEntry? {
        try await request(
            endpoint: "/workspaces/\(workspaceId)/time_entries/\(timeEntryId)/stop",
            httpMethod: .patch,
        )
    }

    /// Создаёт новую текущую запись времени с указанными параметрами и началом в момент вызова.
    func createTimeEntry(
        workspaceId: Int,
        projectId: Int? = nil,
        description: String? = nil,
    ) async throws -> TogglTimeEntry? {
        // Словарь для формирования JSON тела запроса
        // TODO: при необходимости создать Encodable структуру для лучшего контроля типов данных
        var payload: [String: Any] = [
            "workspace_id": workspaceId,
            "created_with": "TogglBar",
            "duration": -1,  // -1 означает "таймер запущен"
            "start": TogglAPI.isoFormatter.string(from: Date())  // текущий момент времени в UTC
        ]

        if let description = description {
            payload["description"] = description
        }

        if let projectId = projectId {
            payload["project_id"] = projectId
        }

        // Сериализуем словарь в Data
        let body = try JSONSerialization.data(withJSONObject: payload)

        return try await request(
            endpoint: "/workspaces/\(workspaceId)/time_entries",
            httpMethod: .post,
            body: body,
        )
    }

    // MARK: Generic request
    private func request<T: Decodable>(
        endpoint: String,
        httpMethod: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        body: Data? = nil,
    ) async throws -> T {
        let urlRequest = try buildURLRequest(
            endpoint: endpoint,
            httpMethod: httpMethod,
            queryItems: queryItems,
            body: body
        )

        let (data, response) = try await executeRequest(urlRequest, httpMethod: httpMethod)
        try validateResponse(response, data: data)

        return try decodeResponse(data)
    }

    /// Формирует URLRequest с указанными параметрами.
    private func buildURLRequest(
        endpoint: String,
        httpMethod: HTTPMethod,
        queryItems: [URLQueryItem],
        body: Data?,
    ) throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + endpoint) else {
            throw TogglAPIError.invalidURL
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw TogglAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue

        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let credentials = "\(apiKey):api_token"
        let base64Credentials = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")

        return request
    }

    /// Выполняет HTTP-запрос и возвращает данные и ответ.
    private func executeRequest(
        _ request: URLRequest,
        httpMethod: HTTPMethod,
    ) async throws -> (Data, URLResponse) {
        do {
            Log.api.debug(
                "🛠️ Запрашиваем \(httpMethod.rawValue, privacy: .public) \(request.url?.absoluteString ?? "?", privacy: .public)..."
            )
            return try await self.session.data(for: request)
        } catch let error as CancellationError {
            throw error
        } catch let error as URLError {
            throw TogglAPIError.network(error)
        } catch {
            throw TogglAPIError.unknown(error)
        }
    }

    /// Проверяет HTTP-ответ и выбрасывает ошибку при неуспешном статусе.
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TogglAPIError.invalidResponse
        }

        updateRateLimitInfo(httpResponse: httpResponse)
        logRateLimitInfo()

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401, 403:
            throw TogglAPIError.unauthorized
        case 402, 429:
            throw buildRateLimitError()
        default:
            let body = String(data: data, encoding: .utf8)
            throw TogglAPIError.http(statusCode: httpResponse.statusCode, body: body)
        }
    }

    /// Декодирует JSON-данные в указанный тип.
    private func decodeResponse<T: Decodable>(_ data: Data) throws -> T {
        guard !data.isEmpty else {
            throw TogglAPIError.decoding(URLError(.zeroByteResource))
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw TogglAPIError.decoding(error)
        }
    }

    /// Логирует информацию о квотах API.
    private func logRateLimitInfo() {
        guard let rateLimit = rateLimitSubject.value else { return }
        Log.api.info(
            "📊 Осталось запросов: \(rateLimit.remaining ?? 0, privacy: .public), сброс через: \(rateLimit.resetAt?.formatted(.relative(presentation: .numeric)) ?? "?", privacy: .public)"
        )
    }

    /// Создаёт ошибку превышения лимита запросов.
    private func buildRateLimitError() -> TogglAPIError {
        var resetsIn: String?
        if let rateLimit = rateLimitSubject.value {
            resetsIn = rateLimit.resetAt?.formatted(.relative(presentation: .numeric)) ?? "?"
        }
        return TogglAPIError.rateLimited(resetsIn: resetsIn)
    }

    // MARK: Helpers
    /// Выводит отформатированный JSON в консоль.
    private func prettyPrintData(data: Data) {
        #if DEBUG
            if let json = try? JSONSerialization.jsonObject(with: data),
                let prettyData = try? JSONSerialization.data(
                    withJSONObject: json, options: .prettyPrinted),
                let prettyString = String(data: prettyData, encoding: .utf8) {
                Log.api.debug("\(prettyString, privacy: .public)")
            } else {
                Log.api.error("❌ Не удалось распарсить JSON")
            }
        #endif
    }

    /// Получает сведения о квотах TogglTrack из заголовков ответа API и публикует их.
    private func updateRateLimitInfo(httpResponse: HTTPURLResponse) {
        let remaining = httpResponse.value(forHTTPHeaderField: "X-Toggl-Quota-Remaining")
            .flatMap(Int.init)
        let resetsInSeconds = httpResponse.value(forHTTPHeaderField: "X-Toggl-Quota-Resets-In")
            .flatMap(TimeInterval.init)
        let resetAt = resetsInSeconds.map { Date.now.addingTimeInterval($0) }

        rateLimitSubject.send(
            RateLimitInfo(remaining: remaining, resetAt: resetAt)
        )
    }
}

// MARK: HTTP Methods
/// HTTP методы, используемые для взаимодействия с API TogglTrack
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
}

// MARK: API errors
enum TogglAPIError: LocalizedError {
    case invalidURL
    case unauthorized
    case invalidResponse
    case rateLimited(resetsIn: String?)
    case http(statusCode: Int, body: String?)
    case network(URLError)
    case decoding(Error)
    case unknown(Error)

    // Для localizedDescription
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некорректный URL запроса"
        case .unauthorized:
            return "Нет доступа. Проверьте API key"
        case .invalidResponse:
            return "Некорректный ответ API"
        case .rateLimited(let resetsIn):
            return "Превышен лимит запросов"
                + (resetsIn.map { ". Повторите через \($0) сек" } ?? "")
        case .http(let statusCode, _):
            return "Ошибка сервера (HTTP \(statusCode))"
        case .network(let error):
            return error.localizedDescription
        case .decoding(let error):
            return "Ошибка декодирования JSON: \(error.localizedDescription)"
        case .unknown(let error):
            return "Неизвестная ошибка: \(error.localizedDescription)"
        }
    }

    // Для error.failureReason
    var failureReason: String? {
        switch self {
        case .http(_, let body):
            // Ограничиваем длину, чтобы не засорять логи
            guard let body = body else { return nil }
            let truncated = body.prefix(500)
            return "Ответ сервера: \(truncated)"
        case .decoding(let error):
            return "Детали: \(error)"
        default:
            return nil
        }
    }
}
