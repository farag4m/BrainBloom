import Foundation

enum AppLogger {
    private static let fileName = "Logs"
    private static let queue = DispatchQueue(label: "AppLogger.queue", qos: .utility)
    private static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func log(_ message: String, category: String = "Runtime") {
        let entry = "\(formatter.string(from: Date())) [\(category)] \(message)\n"
        queue.async {
            append(entry)
        }
    }

    static func log(error: Error, context: String, category: String = "Runtime") {
        log("\(context): \(error.localizedDescription)", category: category)
    }

    private static func append(_ entry: String) {
        guard let data = entry.data(using: .utf8) else { return }
        let fileManager = FileManager.default
        let logURL = fileURL(fileManager: fileManager)

        if !fileManager.fileExists(atPath: logURL.path) {
            fileManager.createFile(atPath: logURL.path, contents: nil)
        }

        do {
            let handle = try FileHandle(forWritingTo: logURL)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
        } catch {
            fputs("AppLogger failure: \(error.localizedDescription)\n", stderr)
        }
    }

    private static func fileURL(fileManager: FileManager) -> URL {
        if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: AppConfig.appGroupID) {
            return groupURL.appendingPathComponent(fileName, isDirectory: false)
        }

        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return tempDirectory.appendingPathComponent(fileName, isDirectory: false)
    }
}
