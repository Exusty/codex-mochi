import Combine
import Foundation

@MainActor
public final class QuotaStore: ObservableObject {
    @Published public private(set) var snapshot: QuotaSnapshot?
    @Published public private(set) var error: QuotaError?
    @Published public private(set) var isRefreshing = false
    @Published public private(set) var isStale = false
    @Published public private(set) var pace: UsagePace
    @Published public private(set) var localTokens: LocalTokenSnapshot

    private let fetcher: any QuotaFetching
    private let historyRepository: UsageHistoryRepository?
    private let tokenSnapshotProvider: @Sendable () -> LocalTokenSnapshot
    private var historySamples: [UsageSample]

    public init(
        fetcher: any QuotaFetching = QuotaClient(),
        historyURL: URL? = UsageHistoryRepository.defaultURL,
        tokenSnapshotProvider: @escaping @Sendable () -> LocalTokenSnapshot = {
            LocalTokenLogReader().read()
        }
    ) {
        self.fetcher = fetcher
        self.tokenSnapshotProvider = tokenSnapshotProvider
        historyRepository = historyURL.map(UsageHistoryRepository.init(fileURL:))
        historySamples = (try? historyRepository?.load()) ?? []
        pace = UsagePaceCalculator.calculate(samples: historySamples)
        localTokens = tokenSnapshotProvider()
    }

    public func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        localTokens = tokenSnapshotProvider()

        do {
            let newSnapshot = try await fetcher.fetch()
            snapshot = newSnapshot
            historySamples = UsageHistoryRecorder.appending(snapshot: newSnapshot, to: historySamples)
            pace = UsagePaceCalculator.calculate(samples: historySamples, now: newSnapshot.fetchedAt)
            try? historyRepository?.save(historySamples)
            error = nil
            isStale = false
        } catch let quotaError as QuotaError {
            error = quotaError
            isStale = snapshot != nil
        } catch {
            self.error = .transport
            isStale = snapshot != nil
        }
    }
}
