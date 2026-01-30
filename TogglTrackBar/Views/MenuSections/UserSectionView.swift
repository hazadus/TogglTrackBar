import SwiftUI

/// Часть меню с инфой о пользователе TogglTrack и квотах API.
struct UserSectionView: View {
    @EnvironmentObject var togglVM: TogglViewModel

    var body: some View {
        // MARK: О пользователе
        if let user = togglVM.user {
            Text(user.email)
                .foregroundStyle(.secondary)
        }

        // MARK: Квоты API
        if let rateLimit = togglVM.rateLimit {
            if let remaining = rateLimit.remaining {
                Text("    \(remaining) запросов осталось")
                    .foregroundStyle(.secondary)
            }

            if let resetAt = rateLimit.resetAt, rateLimit.isLow {
                Text("    Сброс \(Formatters.dateTime.string(from: resetAt))")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
