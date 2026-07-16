import Foundation

public struct AuthCredential: Equatable, Sendable {
    public let accessToken: String
    public let accountID: String?

    public init(accessToken: String, accountID: String?) {
        self.accessToken = accessToken
        self.accountID = accountID
    }
}

public enum AuthLoader {
    private static let maxAuthBytes = 256 * 1024

    public static func load(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) throws -> AuthCredential {
        let base = environment["CODEX_HOME"].map { URL(fileURLWithPath: $0, isDirectory: true) }
            ?? homeDirectory.appendingPathComponent(".codex", isDirectory: true)
        let url = base.appendingPathComponent("auth.json")
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        guard let size = attributes?[.size] as? NSNumber else { throw QuotaError.signedOut }
        guard size.intValue <= maxAuthBytes else { throw QuotaError.invalidAuth }
        guard
            let data = try? Data(contentsOf: url),
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw QuotaError.invalidAuth
        }
        let tokens = root["tokens"] as? [String: Any] ?? root
        guard let token = (tokens["access_token"] ?? tokens["accessToken"]) as? String, !token.isEmpty else {
            throw QuotaError.invalidAuth
        }
        let explicitID = (tokens["account_id"] ?? tokens["accountId"]) as? String
        return AuthCredential(accessToken: token, accountID: explicitID ?? accountID(fromJWT: token))
    }

    public static func accountID(fromJWT token: String) -> String? {
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count >= 2 else { return nil }
        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        payload += String(repeating: "=", count: (4 - payload.count % 4) % 4)
        guard
            let data = Data(base64Encoded: payload),
            let value = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }
        return (value["https://api.openai.com/auth.chatgpt_account_id"]
            ?? value["chatgpt_account_id"]) as? String
    }
}
