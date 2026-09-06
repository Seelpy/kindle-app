import AppKit
import Foundation

@MainActor
final class KindleScreenShareStore: ObservableObject {
    enum Status: Equatable {
        case disconnected
        case connecting
        case streaming
        case failed(String)

        var title: String {
            switch self {
            case .disconnected: return "Не подключено"
            case .connecting: return "Подключение…"
            case .streaming: return "Экран передаётся"
            case .failed(let message): return message
            }
        }
    }

    @Published var host = "192.168.0.197"
    @Published var port = "2222"
    @Published private(set) var status: Status = .disconnected
    @Published private(set) var frame: NSImage?
    @Published private(set) var rotation = 0
    @Published private(set) var isStreaming = false

    private var streamTask: Task<Void, Never>?
    private var currentProcess: Process?

    func connect() {
        guard streamTask == nil else {
            disconnect()
            return
        }

        guard let endpoint = validatedEndpoint() else {
            status = .failed("Проверь IP-адрес и порт")
            return
        }

        status = .connecting
        isStreaming = true
        streamTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                do {
                    let data = try await captureFrame(host: endpoint.host, port: endpoint.port)
                    guard !Task.isCancelled else { break }
                    guard let image = Self.makeImage(from: data) else {
                        throw ScreenShareError.invalidFrame
                    }
                    frame = image
                    status = .streaming
                } catch is CancellationError {
                    break
                } catch {
                    status = .failed(Self.message(for: error))
                    break
                }

                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }

            streamTask = nil
            isStreaming = false
        }
    }

    func disconnect() {
        currentProcess?.terminate()
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
        status = .disconnected
    }

    func rotateLeft() {
        rotation = (rotation + 270) % 360
    }

    func rotateRight() {
        rotation = (rotation + 90) % 360
    }

    private func validatedEndpoint() -> (host: String, port: Int)? {
        let cleanHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-:")
        guard !cleanHost.isEmpty,
              cleanHost.unicodeScalars.allSatisfy({ allowed.contains($0) }),
              !cleanHost.hasPrefix("-"),
              cleanHost.count <= 253,
              let cleanPort = Int(port),
              (1...65535).contains(cleanPort) else { return nil }
        return (cleanHost, cleanPort)
    }

    private func captureFrame(host: String, port: Int) async throws -> Data {
        let process = Process()
        let output = Pipe()
        let errors = Pipe()

        let sshDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".ssh", isDirectory: true)
        let supportedKeys = ["id_ed25519", "id_ecdsa", "id_rsa"]
        let identity = supportedKeys
            .map { sshDirectory.appendingPathComponent($0) }
            .first { FileManager.default.fileExists(atPath: $0.path) }

        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        var arguments = [
            "-p", String(port),
            "-o", "BatchMode=yes",
            "-o", "StrictHostKeyChecking=yes",
            "-o", "ConnectTimeout=5",
            "-o", "ServerAliveInterval=3",
            "-o", "ServerAliveCountMax=1"
        ]
        if let identity {
            arguments += ["-o", "IdentitiesOnly=yes", "-i", identity.path]
        }
        arguments += [
            "root@\(host)",
            "dd if=/dev/fb0 bs=4642560 count=1 2>/dev/null"
        ]
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = errors

        currentProcess = process
        defer { currentProcess = nil }
        try process.run()

        return try await withTaskCancellationHandler {
            let outputTask = Task.detached(priority: .utility) {
                output.fileHandleForReading.readDataToEndOfFile()
            }
            let errorTask = Task.detached(priority: .utility) {
                errors.fileHandleForReading.readDataToEndOfFile()
            }
            let data = await outputTask.value
            let errorData = await errorTask.value
            process.waitUntilExit()
            try Task.checkCancellation()

            guard process.terminationStatus == 0 else {
                let detail = String(data: errorData, encoding: .utf8) ?? ""
                throw ScreenShareError.ssh(detail)
            }
            return data
        } onCancel: {
            process.terminate()
        }
    }

    nonisolated private static func makeImage(from data: Data) -> NSImage? {
        let sourceWidth = 1872
        let visibleWidth = 1860
        let height = 2480
        guard data.count >= sourceWidth * height,
              let provider = CGDataProvider(data: data as CFData),
              let source = CGImage(
                width: sourceWidth,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 8,
                bytesPerRow: sourceWidth,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ),
              let cropped = source.cropping(to: CGRect(x: 0, y: 0, width: visibleWidth, height: height)) else { return nil }

        return NSImage(cgImage: cropped, size: NSSize(width: visibleWidth, height: height))
    }

    nonisolated private static func message(for error: Error) -> String {
        guard case ScreenShareError.ssh(let detail) = error else {
            return "Не удалось получить изображение"
        }
        if detail.contains("Host key verification failed") {
            return "Сначала подтвердите ключ Kindle в Терминале"
        }
        if detail.contains("Permission denied") {
            return "SSH-ключ не принят Kindle"
        }
        if detail.contains("Connection refused") || detail.contains("timed out") {
            return "Kindle недоступен по SSH"
        }
        return "Ошибка безопасного SSH-подключения"
    }
}

private enum ScreenShareError: Error {
    case invalidFrame
    case ssh(String)
}
