import Foundation

enum ReadingMoment: String, CaseIterable, Codable, Equatable, Identifiable {
    case now
    case evening
    case morning

    var id: String { rawValue }

    var title: String {
        switch self {
        case .now: return "Сейчас"
        case .evening: return "Вечером"
        case .morning: return "Завтра утром"
        }
    }

    var symbol: String {
        switch self {
        case .now: return "clock"
        case .evening: return "moon.stars"
        case .morning: return "sun.horizon"
        }
    }
}

struct ActiveBook: Codable, Equatable {
    var title = "Анна Каренина"
    var author = "Лев Толстой"
    var chapter = "Часть II, глава 8"
    var page = 163
    var progress = 0.28
    var resumeNote = "Начни с разговора у окна"
}

struct ReadingSession: Codable, Equatable {
    enum Status: String, Codable, Equatable {
        case ready
        case reading
        case complete
    }

    var status: Status = .ready
    var goalPages = 5
    var pagesCompleted = 0
    var selectedMoment: ReadingMoment = .now
}

struct SharedReadingState: Codable, Equatable {
    var book: ActiveBook? = ActiveBook()
    var session = ReadingSession()
    var revision = 1
    var updatedAt = Date()
}
