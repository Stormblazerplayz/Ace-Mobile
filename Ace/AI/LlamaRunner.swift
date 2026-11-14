import Foundation

#if canImport(llama)
import llama

/// Runs a GGUF model (LFM3 Omni) on the iPad with llama.cpp.
/// Everything here is slow work, so call it off the main thread.
final class LlamaRunner: @unchecked Sendable {
    enum RunnerError: LocalizedError {
        case load, context, prompt
        var errorDescription: String? {
            switch self {
            case .load: return "The model file couldn't be loaded."
            case .context: return "There wasn't enough memory to start the model."
            case .prompt: return "The question was too long for the model."
            }
        }
    }

    private static let backendReady: Bool = {
        llama_backend_init()
        return true
    }()

    private let model: OpaquePointer
    private let vocab: OpaquePointer?
    private let lock = NSLock()
    private let contextSize: UInt32 = 4096

    init(modelPath: String) throws {
        _ = LlamaRunner.backendReady
        var params = llama_model_default_params()
        #if targetEnvironment(simulator)
        params.n_gpu_layers = 0
        #else
        params.n_gpu_layers = 99
        #endif
        guard let m = llama_model_load_from_file(modelPath, params) else { throw RunnerError.load }
        model = m
        vocab = llama_model_get_vocab(m)
    }

    deinit {
        llama_model_free(model)
    }

    /// Makes a reply. `system` is how Ace should act, `user` is the question.
    func generate(system: String, user: String, maxTokens: Int) throws -> String {
        lock.lock()
        defer { lock.unlock() }

        let prompt = buildPrompt(system: system, user: user)
        var tokens = tokenize(prompt)
        guard !tokens.isEmpty else { throw RunnerError.prompt }
        if tokens.count > Int(contextSize) - maxTokens - 8 {
            // Keep the end of the prompt (the question) if it's too long.
            tokens = Array(tokens.suffix(Int(contextSize) - maxTokens - 8))
        }

        var cparams = llama_context_default_params()
        cparams.n_ctx = contextSize
        cparams.n_batch = 512
        let threads = Int32(max(1, min(6, ProcessInfo.processInfo.activeProcessorCount - 2)))
        cparams.n_threads = threads
        cparams.n_threads_batch = threads
        guard let ctx = llama_init_from_model(model, cparams) else { throw RunnerError.context }
        defer { llama_free(ctx) }

        let sampler = llama_sampler_chain_init(llama_sampler_chain_default_params())
        defer { llama_sampler_free(sampler) }
        llama_sampler_chain_add(sampler, llama_sampler_init_top_k(40))
        llama_sampler_chain_add(sampler, llama_sampler_init_top_p(0.9, 1))
        llama_sampler_chain_add(sampler, llama_sampler_init_temp(0.6))
        llama_sampler_chain_add(sampler, llama_sampler_init_dist(UInt32.random(in: 0...UInt32.max)))

        // Read the prompt in chunks the size of a batch.
        var start = 0
        while start < tokens.count {
            let end = min(start + 512, tokens.count)
            var chunk = Array(tokens[start..<end])
            let ok = chunk.withUnsafeMutableBufferPointer { buf -> Bool in
                let batch = llama_batch_get_one(buf.baseAddress, Int32(buf.count))
                return llama_decode(ctx, batch) == 0
            }
            guard ok else { throw RunnerError.prompt }
            start = end
        }

        var bytes: [UInt8] = []
        for _ in 0..<maxTokens {
            var token = llama_sampler_sample(sampler, ctx, -1)
            if llama_vocab_is_eog(vocab, token) { break }
            bytes += piece(token)
            if let text = String(bytes: bytes, encoding: .utf8), Self.hitStop(text) { break }
            let ok = withUnsafeMutablePointer(to: &token) { ptr -> Bool in
                let batch = llama_batch_get_one(ptr, 1)
                return llama_decode(ctx, batch) == 0
            }
            if !ok { break }
        }
        let text = String(decoding: bytes, as: UTF8.self)
        return Self.clean(text)
    }

    // MARK: Helpers

    private func buildPrompt(system: String, user: String) -> String {
        if let template = llama_model_chat_template(model, nil) {
            let roles = ["system", "user"].map { strdup($0) }
            let contents = [system, user].map { strdup($0) }
            defer {
                roles.forEach { free($0) }
                contents.forEach { free($0) }
            }
            var messages = [
                llama_chat_message(role: UnsafePointer(roles[0]), content: UnsafePointer(contents[0])),
                llama_chat_message(role: UnsafePointer(roles[1]), content: UnsafePointer(contents[1])),
            ]
            var buffer = [CChar](repeating: 0, count: 8192)
            var n = llama_chat_apply_template(template, &messages, messages.count, true, &buffer, Int32(buffer.count))
            if n > Int32(buffer.count) {
                buffer = [CChar](repeating: 0, count: Int(n) + 1)
                n = llama_chat_apply_template(template, &messages, messages.count, true, &buffer, Int32(buffer.count))
            }
            if n > 0 {
                let used = buffer.prefix(Int(n)).map { UInt8(bitPattern: $0) }
                return String(decoding: used, as: UTF8.self)
            }
        }
        // ChatML, which LFM models use, if the file has no template.
        return "<|im_start|>system\n\(system)<|im_end|>\n<|im_start|>user\n\(user)<|im_end|>\n<|im_start|>assistant\n"
    }

    private func tokenize(_ text: String) -> [llama_token] {
        let utf8Count = Int32(text.utf8.count)
        var tokens = [llama_token](repeating: 0, count: Int(utf8Count) + 16)
        var n = llama_tokenize(vocab, text, utf8Count, &tokens, Int32(tokens.count), true, true)
        if n < 0 {
            tokens = [llama_token](repeating: 0, count: Int(-n))
            n = llama_tokenize(vocab, text, utf8Count, &tokens, Int32(tokens.count), true, true)
        }
        return n > 0 ? Array(tokens.prefix(Int(n))) : []
    }

    private func piece(_ token: llama_token) -> [UInt8] {
        var buffer = [CChar](repeating: 0, count: 64)
        var n = llama_token_to_piece(vocab, token, &buffer, Int32(buffer.count), 0, false)
        if n < 0 {
            buffer = [CChar](repeating: 0, count: Int(-n))
            n = llama_token_to_piece(vocab, token, &buffer, Int32(buffer.count), 0, false)
        }
        guard n > 0 else { return [] }
        return buffer.prefix(Int(n)).map { UInt8(bitPattern: $0) }
    }

    private static let stops = ["<|im_end|>", "<|im_start|>", "<|endoftext|>"]

    private static func hitStop(_ text: String) -> Bool {
        stops.contains { text.contains($0) }
    }

    private static func clean(_ text: String) -> String {
        var t = text
        for s in stops {
            if let r = t.range(of: s) { t = String(t[..<r.lowerBound]) }
        }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
#endif
