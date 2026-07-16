import Foundation

public protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public final class URLSessionTransport: HTTPTransport, @unchecked Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuotaError.unavailable
        }
        return (data, httpResponse)
    }
}

public protocol QuotaFetching: Sendable {
    func fetch() async throws -> QuotaSnapshot
}

public struct QuotaClient: QuotaFetching, Sendable {
    public static let usageURL = URL(string: "https://chatgpt.com/backend-api/wham/usage")!
    private static let maxResponseBytes = 1_048_576

    private let transport: any HTTPTransport
    private let credentialProvider: @Sendable () throws -> AuthCredential

    public init(
        transport: any HTTPTransport = URLSessionTransport(),
        credentialProvider: @escaping @Sendable () throws -> AuthCredential = { try AuthLoader.load() }
    ) {
        self.transport = transport
        self.credentialProvider = credentialProvider
    }

    public func fetch() async throws -> QuotaSnapshot {
        let credential: AuthCredential
        do {
            credential = try credentialProvider()
        } catch let error as QuotaError {
            throw error
        } catch {
            throw QuotaError.invalidAuth
        }

        var request = URLRequest(
            url: Self.usageURL,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 15
        )
        request.httpMethod = "GET"
        request.setValue("Bearer \(credential.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Codex Desktop", forHTTPHeaderField: "originator")
        request.setValue("CODEX", forHTTPHeaderField: "OAI-Product-Sku")
        if let accountID = credential.accountID, !accountID.isEmpty {
            request.setValue(accountID, forHTTPHeaderField: "ChatGPT-Account-Id")
        }

        do {
            let (data, response) = try await transport.data(for: request)
            switch response.statusCode {
            case 200 ..< 300:
                guard data.count <= Self.maxResponseBytes else { throw QuotaError.responseTooLarge }
                return try QuotaParser.parse(data: data)
            case 401, 403:
                throw QuotaError.unauthorized
            case 429:
                throw QuotaError.rateLimited
            default:
                throw QuotaError.unavailable
            }
        } catch let error as QuotaError {
            throw error
        } catch {
            throw QuotaError.transport
        }
    }
}
