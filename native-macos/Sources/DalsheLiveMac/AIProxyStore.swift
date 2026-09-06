import Foundation

@MainActor
final class AIProxyStore: ObservableObject {
    enum Status: Equatable {
        case stopped
        case starting
        case ready(Int)
        case needsLogin
        case unavailable
        case failed(String)

        var title: String {
            switch self {
            case .stopped: return "AI выключен"
            case .starting: return "AI запускается…"
            case .ready: return "AI готов"
            case .needsLogin: return "Нужен вход в AI"
            case .unavailable: return "AI-шлюз не установлен"
            case .failed(let message): return message
            }
        }

        var symbol: String {
            switch self {
            case .ready: return "sparkles"
            case .starting: return "hourglass"
            case .needsLogin: return "person.crop.circle.badge.exclamationmark"
            case .stopped, .unavailable, .failed: return "exclamationmark.triangle"
            }
        }
    }

    @Published private(set) var status: Status = .stopped
    @Published private(set) var endpoint = "http://192.168.0.174:8317/v1"

    private var process: Process?

    func startIfNeeded() async {
        if await refresh() { return }

        guard let executable = executableURL else {
            status = .unavailable
            return
        }
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            status = .failed("Нет настройки AI-шлюза")
            return
        }

        status = .starting
        let process = Process()
        process.executableURL = executable
        process.arguments = ["-config", configURL.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            self.process = process
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            _ = await refresh()
        } catch {
            status = .failed("Не удалось запустить AI-шлюз")
        }
    }

    @discardableResult
    func refresh() async -> Bool {
        guard let configuration = configuration else {
            status = .failed("Нет настройки AI-шлюза")
            return false
        }

        endpoint = "http://\(configuration.host):\(configuration.port)/v1"
        guard let url = URL(string: endpoint + "/models") else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 3
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                status = .failed("AI-шлюз не отвечает")
                return false
            }
            let models = (try? JSONDecoder().decode(ModelList.self, from: data).data.count) ?? 0
            status = models > 0 ? .ready(models) : .needsLogin
            return true
        } catch {
            status = .stopped
            return false
        }
    }

    func stop() {
        process?.terminate()
        process = nil
        status = .stopped
    }

    private var executableURL: URL? {
        let bundled = Bundle.main.resourceURL?.appendingPathComponent("cli-proxy-api")
        let installed = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cli-proxy-api/bin/cli-proxy-api")
        return [bundled, installed]
            .compactMap { $0 }
            .first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }

    private var configURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cli-proxy-api/config.yaml")
    }

    private var configuration: Configuration? {
        guard let text = try? String(contentsOf: configURL, encoding: .utf8) else { return nil }
        let host = capture(#"(?m)^host:\s*[\"']?([^\"'\s]+)"#, in: text) ?? "127.0.0.1"
        let port = Int(capture(#"(?m)^port:\s*(\d+)"#, in: text) ?? "8317") ?? 8317
        guard let apiKey = capture(#"(?m)^\s*-\s*[\"']?([^\"'\s]+)"#, in: text) else { return nil }
        return Configuration(host: host, port: port, apiKey: apiKey)
    }

    private func capture(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }
}

private struct Configuration {
    let host: String
    let port: Int
    let apiKey: String
}

private struct ModelList: Decodable {
    struct Model: Decodable { let id: String }
    let data: [Model]
}
