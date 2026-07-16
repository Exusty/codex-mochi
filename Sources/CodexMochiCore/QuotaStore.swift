import Combine
import Foundation

@MainActor
public final class QuotaStore: ObservableObject {
    @Published public private(set) var snapshot: QuotaSnapshot?
    @Published public private(set) var error: QuotaError?
    @Published public private(set) var isRefreshing = false
    @Published public private(set) var isStale = false

    private let fetcher: any QuotaFetching

    public init(fetcher: any QuotaFetching = QuotaClient()) {
        self.fetcher = fetcher
    }

    public func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            snapshot = try await fetcher.fetch()
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
