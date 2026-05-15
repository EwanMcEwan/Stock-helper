import Foundation
import os.log

private let logger = Logger(subsystem: "com.stockhelper", category: "YahooFinance")

/// Uses Yahoo Finance's unofficial v1/v8 JSON endpoints.
/// These are not part of an official public API — they can change without notice.
final class YahooFinanceProvider: MarketDataProvider {
    let name = "YahooFinance"
    private let client: APIClient
    private let rateLimiter: RateLimiter
    private let baseURL = "https://query1.finance.yahoo.com"
    private let provider = "yahoo"

    init(client: APIClient, rateLimiter: RateLimiter) {
        self.client = client
        self.rateLimiter = rateLimiter
    }

    // MARK: - Search

    func searchSymbols(_ query: String) async throws -> [Asset] {
        await rateLimiter.waitForToken(provider: provider)
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/v1/finance/search?q=\(encoded)&quotesCount=20&newsCount=0&listsCount=0")
        else { throw APIError.invalidURL }

        let response = try await client.fetch(YahooSearchResponse.self, from: url,
                                              headers: yahooHeaders())
        return response.quotes.compactMap(\.asAsset)
    }

    // MARK: - History

    func fetchHistory(symbol: String, range: DateInterval, interval: BarInterval) async throws -> [PriceBar] {
        await rateLimiter.waitForToken(provider: provider)

        let from = Int(range.start.timeIntervalSince1970)
        let to   = Int(range.end.timeIntervalSince1970)
        let iv   = interval.rawValue

        guard let url = URL(string: "\(baseURL)/v8/finance/chart/\(symbol)?period1=\(from)&period2=\(to)&interval=\(iv)&events=div,splits")
        else { throw APIError.invalidURL }

        let data = try await client.fetchData(from: url, headers: yahooHeaders())
        return try parseChartResponse(data, symbol: symbol)
    }

    // MARK: - Quote

    func fetchQuote(symbol: String) async throws -> Quote {
        await rateLimiter.waitForToken(provider: provider)
        guard let url = URL(string: "\(baseURL)/v8/finance/chart/\(symbol)?range=1d&interval=1m")
        else { throw APIError.invalidURL }

        let data = try await client.fetchData(from: url, headers: yahooHeaders())
        return try parseQuoteResponse(data, symbol: symbol)
    }

    // MARK: - Private parsing

    private func parseChartResponse(_ data: Data, symbol: String) throws -> [PriceBar] {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard
            let chart = json?["chart"] as? [String: Any],
            let results = chart["result"] as? [[String: Any]],
            let result = results.first,
            let timestamps = result["timestamp"] as? [Int],
            let indicators = result["indicators"] as? [String: Any],
            let quote = (indicators["quote"] as? [[String: Any]])?.first
        else { throw APIError.noData }

        let opens     = quote["open"]   as? [Double?] ?? []
        let highs     = quote["high"]   as? [Double?] ?? []
        let lows      = quote["low"]    as? [Double?] ?? []
        let closes    = quote["close"]  as? [Double?] ?? []
        let volumes   = quote["volume"] as? [Double?] ?? []

        let adjCloses: [Double?]
        if let adjclose = (indicators["adjclose"] as? [[String: Any]])?.first,
           let adj = adjclose["adjclose"] as? [Double?] {
            adjCloses = adj
        } else {
            adjCloses = Array(repeating: nil, count: timestamps.count)
        }

        var bars: [PriceBar] = []
        for i in 0..<timestamps.count {
            guard
                let o = opens[safe: i] ?? nil,
                let h = highs[safe: i] ?? nil,
                let l = lows[safe: i] ?? nil,
                let c = closes[safe: i] ?? nil
            else { continue }

            let date = Date(timeIntervalSince1970: TimeInterval(timestamps[i]))
            let vol  = volumes[safe: i] ?? nil ?? 0.0
            let adj  = adjCloses[safe: i] ?? nil

            bars.append(PriceBar(date: date, open: o, high: h, low: l, close: c, volume: vol, adjustedClose: adj))
        }
        return bars
    }

    private func parseQuoteResponse(_ data: Data, symbol: String) throws -> Quote {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard
            let chart = json?["chart"] as? [String: Any],
            let results = chart["result"] as? [[String: Any]],
            let result = results.first,
            let meta = result["meta"] as? [String: Any]
        else { throw APIError.noData }

        let price          = meta["regularMarketPrice"] as? Double ?? 0
        let prevClose      = meta["chartPreviousClose"] as? Double ?? price
        let change         = price - prevClose
        let changePercent  = prevClose != 0 ? (change / prevClose) : 0

        return Quote(
            symbol: symbol,
            price: price,
            change: change,
            changePercent: changePercent,
            volume: meta["regularMarketVolume"] as? Double ?? 0,
            marketCap: meta["marketCap"] as? Double,
            timestamp: Date()
        )
    }

    private func yahooHeaders() -> [String: String] {
        [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
            "Accept-Language": "en-US,en;q=0.9"
        ]
    }
}

// MARK: - Response DTOs

private struct YahooSearchResponse: Decodable {
    let quotes: [YahooQuoteResult]
}

private struct YahooQuoteResult: Decodable {
    let symbol: String?
    let longname: String?
    let shortname: String?
    let exchDisp: String?
    let typeDisp: String?
    let currency: String?

    var asAsset: Asset? {
        guard let symbol else { return nil }
        let name = longname ?? shortname ?? symbol
        let kind = AssetKind.from(typeDisp ?? "")
        return Asset(
            id: symbol,
            name: name,
            exchange: exchDisp ?? "",
            kind: kind,
            currency: currency ?? "USD",
            description: nil
        )
    }
}

private extension AssetKind {
    static func from(_ typeDisp: String) -> AssetKind {
        switch typeDisp.lowercased() {
        case "etf": return .etf
        case "etn": return .etn
        case "etc": return .etc
        case "etp": return .etp
        default:    return .stock
        }
    }
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
