import Foundation

@MainActor
final class ReadingStore: ObservableObject {
    enum ConnectionState: String, Equatable {
        case connected = "Синхронизировано"
        case syncing = "Синхронизация…"
        case offline = "Kindle не найден"
    }

    @Published private(set) var state = SharedReadingState()
    @Published private(set) var connection: ConnectionState = .connected

    private let saveURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("DalsheLive", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        saveURL = directory.appendingPathComponent("reading-state.json")
        load()
    }

    func select(_ moment: ReadingMoment) {
        mutate { $0.session.selectedMoment = moment }
    }

    func startSession() {
        guard state.session.selectedMoment == .now else { return }
        mutate {
            $0.session.status = .reading
            $0.session.pagesCompleted = max(1, $0.session.pagesCompleted)
        }
    }

    func nextPage() {
        mutate {
            $0.session.pagesCompleted = min($0.session.goalPages, $0.session.pagesCompleted + 1)
            if $0.session.pagesCompleted == $0.session.goalPages {
                $0.session.status = .complete
            }
        }
    }

    func finishSession(note: String) {
        mutate {
            $0.book?.resumeNote = note
            $0.book?.page += $0.session.pagesCompleted
            $0.session = ReadingSession()
        }
    }

    func releaseBook() {
        mutate { $0.book = nil }
    }

    func restoreDemoBook() {
        mutate { $0.book = ActiveBook() }
    }

    func simulateConnection() {
        connection = connection == .connected ? .offline : .connected
    }

    private func mutate(_ update: (inout SharedReadingState) -> Void) {
        update(&state)
        state.revision += 1
        state.updatedAt = Date()
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let saved = try? JSONDecoder().decode(SharedReadingState.self, from: data) else { return }
        state = saved
    }
}
