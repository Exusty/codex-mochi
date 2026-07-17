import Foundation
import Testing
@testable import CodexMochiCore

@Test func quotaClientSendsCodexHeadersAndParsesUsage() async throws {
    let body = Data(#"{"plan_type":"plus","rate_limit":{"primary_window":{"used_percent":22,"limit_window_seconds":604800}}}"#.utf8)
    let transport = RecordingTransport(result: .success((body, response(status: 200))))
    let client = QuotaClient(
        transport: transport,
        credentialProvider: { AuthCredential(accessToken: "secret-token", accountID: "acct_42") }
    )

    let snapshot = try await client.fetch()
    let request = try #require(await transport.lastRequest())

    #expect(snapshot.primaryWeekly?.remainingPercent == 78)
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
        primaryWeekly: QuotaWindow(remainingPercent: 55, resetsAt: nil, windowSeconds: 604_800),
        secondaryWeekly: nil,
        fetchedAt: Date()
    )
    let fetcher = SequenceFetcher(results: [.success(snapshot), .failure(.transport)])
    let store = QuotaStore(
        fetcher: fetcher,
        historyURL: nil,
        tokenSnapshotProvider: { .empty }
    )

    await store.refresh()
    #expect(store.snapshot == snapshot)
    #expect(store.isStale == false)

    await store.refresh()
    #expect(store.snapshot == snapshot)
    #expect(store.isStale)
    #expect(store.error == .transport)
}

@MainActor
@Test func quotaStoreRefreshesLocalTokenSnapshot() async {
    let quota = QuotaSnapshot(
        plan: "Pro",
        primaryWeekly: QuotaWindow(remainingPercent: 98, resetsAt: nil, windowSeconds: 604_800),
        secondaryWeekly: nil,
        fetchedAt: Date()
    )
    let localTokens = LocalTokenSnapshot(
        today: TokenCounts(
            input: 1_200_000,
            cachedInput: 900_000,
            output: 80_000,
            reasoningOutput: 20_000,
            total: 1_280_000
        ),
        recentTokensPerHour: 2_400_000,
        speedMood: .gobbling,
        sampleCount: 12,
        lastUpdatedAt: Date()
    )
    let store = QuotaStore(
        fetcher: SequenceFetcher(results: [.success(quota)]),
        historyURL: nil,
        tokenSnapshotProvider: { localTokens }
    )

    await store.refresh()

    #expect(store.localTokens == localTokens)
    #expect(store.snapshot == quota)
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
