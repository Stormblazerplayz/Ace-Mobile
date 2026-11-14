import Foundation
import UIKit

/// LFM3 Omni, an AI model that runs right on the iPad (no internet needed once it's downloaded).
/// It's off until you turn it on in Settings and download it (about 1.6 GB).
@MainActor
final class LocalModel: ObservableObject {
    static let shared = LocalModel()

    enum State: Equatable {
        case notDownloaded
        case downloading(Double)
        case downloaded
        case loading
        case ready
        case failed(String)
    }

    struct ModelFile {
        let name: String
        let size: Int64
        var url: URL { URL(string: "https://huggingface.co/LiquidAI/LFM3-Omni-2B-GGUF/resolve/main/\(name)")! }
    }

    /// The language model and its picture reader (used for images in a later update).
    static let files: [ModelFile] = [
        ModelFile(name: "LFM3-Omni-2B-Q4_K_M.gguf", size: 1_099_630_080),
        ModelFile(name: "mmproj-LFM3-Omni-2B-Q8_0.gguf", size: 506_842_528),
    ]

    static var totalBytes: Int64 { files.reduce(0) { $0 + $1.size } }

    /// True when this build of the app includes the llama.cpp engine.
    static var engineIncluded: Bool {
        #if canImport(llama)
        return true
        #else
        return false
        #endif
    }

    @Published private(set) var state: State = .notDownloaded

    #if canImport(llama)
    private var runner: LlamaRunner?
    #endif
    private var downloadTask: Task<Void, Never>?
    private var currentDownload: FileDownload?

    private init() {
        state = filesPresent ? .downloaded : .notDownloaded
        NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main) { _ in
            Task { @MainActor in LocalModel.shared.unload() }
        }
    }

    static var folder: URL { Persistence.subfolder("Models") }

    static func path(_ file: ModelFile) -> URL { folder.appendingPathComponent(file.name) }

    var filesPresent: Bool {
        Self.files.allSatisfy { f in
            let attrs = try? FileManager.default.attributesOfItem(atPath: Self.path(f).path)
            let size = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
            return size > f.size / 2
        }
    }

    var isReady: Bool { state == .ready }

    var statusText: String {
        switch state {
        case .notDownloaded: return "Not downloaded"
        case .downloading(let p): return "Downloading \(Int(p * 100))%"
        case .downloaded: return "Downloaded"
        case .loading: return "Starting up"
        case .ready: return "Ready"
        case .failed(let why): return why
        }
    }

    // MARK: Download

    func download() {
        guard downloadTask == nil else { return }
        state = .downloading(0)
        downloadTask = Task { [weak self] in
            await self?.runDownload()
        }
    }

    private func runDownload() async {
        var done: Int64 = 0
        let total = Double(Self.totalBytes)
        do {
            for file in Self.files {
                let dest = Self.path(file)
                if let attrs = try? FileManager.default.attributesOfItem(atPath: dest.path),
                   let size = (attrs[.size] as? NSNumber)?.int64Value, size > file.size / 2 {
                    done += size
                    continue
                }
                let start = done
                let d = FileDownload(destination: dest) { written in
                    Task { @MainActor in
                        LocalModel.shared.state = .downloading(min(0.999, Double(start + written) / total))
                    }
                }
                currentDownload = d
                try await d.run(file.url)
                var url = dest
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                try? url.setResourceValues(values)
                done += file.size
            }
            currentDownload = nil
            downloadTask = nil
            state = .downloaded
            SoundFX.shared.play(.success)
        } catch {
            currentDownload = nil
            downloadTask = nil
            state = .failed((error as NSError).code == NSURLErrorCancelled ? "Download stopped" : "Download failed. Check Wi-Fi and try again.")
        }
    }

    func cancelDownload() {
        currentDownload?.cancel()
    }

    func deleteFiles() {
        unload()
        cancelDownload()
        for f in Self.files { try? FileManager.default.removeItem(at: Self.path(f)) }
        state = .notDownloaded
    }

    // MARK: Running

    /// Loads the model into memory if it isn't already.
    func prepare() async -> Bool {
        #if canImport(llama)
        if runner != nil { return true }
        guard filesPresent else { state = .notDownloaded; return false }
        state = .loading
        let path = Self.path(Self.files[0]).path
        do {
            let r = try await Task.detached(priority: .userInitiated) { try LlamaRunner(modelPath: path) }.value
            runner = r
            state = .ready
            return true
        } catch {
            state = .failed(error.localizedDescription)
            return false
        }
        #else
        return false
        #endif
    }

    func unload() {
        #if canImport(llama)
        runner = nil
        #endif
        if state == .ready || state == .loading { state = filesPresent ? .downloaded : .notDownloaded }
    }

    /// Asks the model. Returns nil if it isn't downloaded, can't run here, or something went wrong.
    func generate(system: String, user: String, maxTokens: Int = 320) async -> String? {
        #if canImport(llama)
        guard await prepare(), let r = runner else { return nil }
        let text = try? await Task.detached(priority: .userInitiated) {
            try r.generate(system: system, user: user, maxTokens: maxTokens)
        }.value
        guard let text, !text.isEmpty else { return nil }
        return text
        #else
        return nil
        #endif
    }
}

/// Downloads one big file and reports how much has come in.
final class FileDownload: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let destination: URL
    private let onProgress: @Sendable (Int64) -> Void
    private var continuation: CheckedContinuation<Void, Error>?
    private var session: URLSession?
    private var task: URLSessionDownloadTask?
    private var lastReport = Date.distantPast

    init(destination: URL, onProgress: @escaping @Sendable (Int64) -> Void) {
        self.destination = destination
        self.onProgress = onProgress
    }

    func run(_ url: URL) async throws {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            continuation = c
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 60
            config.timeoutIntervalForResource = 60 * 60 * 3
            let s = URLSession(configuration: config, delegate: self, delegateQueue: nil)
            session = s
            let t = s.downloadTask(with: url)
            task = t
            t.resume()
        }
    }

    func cancel() {
        task?.cancel()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let now = Date()
        guard now.timeIntervalSince(lastReport) > 0.25 else { return }
        lastReport = now
        onProgress(totalBytesWritten)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let status = (downloadTask.response as? HTTPURLResponse)?.statusCode ?? 200
        guard (200..<300).contains(status) else {
            finish(URLError(.badServerResponse))
            return
        }
        do {
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: location, to: destination)
            finish(nil)
        } catch {
            finish(error)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        finish(error)
        session.finishTasksAndInvalidate()
    }

    private func finish(_ error: Error?) {
        guard let c = continuation else { return }
        continuation = nil
        if let error { c.resume(throwing: error) } else { c.resume() }
    }
}
