import Foundation
import Testing
@testable import CodexMochiCore

@Test func quotaClientSendsCodexHeadersAndParsesUsage() async throws {
    let body = Data(#"{"plan_type":"plus","rate_limit":{"primary_window":{"used_percent":22,"limit_window_seconds":18000}}}"#.utf8)
    let transport = RecordingTransport(result: .success((body, response(status: 200))))
    let client = QuotaClient(
        transport: transport,
        credentialProvider: { AuthCredential(accessToken: "secret-token", accountID: "acct_42") }
    )

    let snapshot = try await client.fetch()
    let request = try #require(await transport.lastRequest())

    #expect(snapshot.fiveHour?.remainingPercent == 78)
    #expect(request.url?.absoluteString == "https://chatgpt.com/backend-api/wham/usage")
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret-token")
    #expect(request.value(forHTTPHeaderField: "ChatGPT-Account-Id") == "acct_42")
    #expect(request.value(forHTTPHeaderField: "originator") == "Codex Desktop")
    #expect(request.value(forHTTPHeaderField: "OAI-Product-Sku") == "CODEX")
}

@Test(arguments: [(401, QuotaError.unauthorized), (429, .rateLimited), (503, .unavailable)])
func quotaClientMapsHTTPFailures(status: Int, expected: QuotaError) async {
    let transport = RecordingTransport(result: .success((Data(), response(status: status))))
    let client = QuotaClient(
        transport: transport,
        credentialProvider: { AuthCredential(accessToken: "token", accountID: nil) }
    )

    do {
        _ = try await client.fetch()
        Issue.record("Expected HTTP failure")
    } catch {
        #expect(error as? QuotaError == expected)
    }
}

@Test func quotaClientRejectsOversizedResponse() async {
    let transport = RecordingTransport(
        result: .success((Data(repeating: 0, count: 1_048_577), response(status: 200)))
    )
    let client = QuotaClient(
        transport: transport,
        credentialProvider: { AuthCredential(accessToken: "token", accountID: nil) }
    )

    do {
        _ = try await client.fetch()
        Issue.record("Expected responseTooLarge")
    } catch {
        #expect(error as? QuotaError == .responseTooLarge)
    }
}

@MainActor
@Test func quotaStoreKeepsLastSnapshotAndMarksItStaleAfterFailure() async {
    let snapshot = QuotaSnapshot(
        plan: "Plus",
        fiveHour: QuotaWindow(remainingPercent: 55, resetsAt: nil, windowSeconds: 18_000),
        weekly: nil,
        fetchedAt: Date()
    )
    let fetcher = SequenceFetcher(results: [.success(snapshot), .failure(.transport)])
    let store = QuotaStore(fetcher: fetcher)

    await store.refresh()
    #expect(store.snapshot == snapshot)
    #expect(store.isStale == false)

    await store.refresh()
    #expect(store.snapshot == snapshot)
    #expect(store.isStale)
    #expect(store.error == .transport)
}

private actor RecordingTransport: HTTPTransport {
    private let result: Result<(Data, HTTPURLResponse), Error>
    private var request: URLRequest?

    init(result: Result<(Data, HTTPURLResponse), Error>) {
        self.result = result
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        self.request = request
        return try result.get()
    }

    func lastRequest() -> URLRequest? { request }
}

private actor SequenceFetcher: QuotaFetching {
    private var results: [Result<QuotaSnapshot, QuotaError>]

    init(results: [Result<QuotaSnapshot, QuotaError>]) {
        self.results = results
    }

    func fetch() async throws -> QuotaSnapshot {
        guard !results.isEmpty else { throw QuotaError.unavailable }
        return try results.removeFirst().get()
    }
}

private func response(status: Int) -> HTTPURLResponse {
    HTTPURLResponse(
        url: URL(string: "https://chatgpt.com/backend-api/wham/usage")!,
        statusCode: status,
        httpVersion: "HTTP/1.1",
        headerFields: nil
    )!
}
