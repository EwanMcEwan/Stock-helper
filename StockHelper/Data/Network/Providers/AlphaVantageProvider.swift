import Foundation

/// Alpha Vantage fallback provider.
/// Free tier: 25 requests/day. Premium keys unlock higher limits.
final class AlphaVantageProvider: MarketDataProvider {
    let name = "AlphaVantage"
    private let client: APIClient
    private let rateLimiter: RateLimiter
    private let apiKey: String
    private let base = "https://www.alphavantage.co/query"
    private let provider = "alphavantage"

    init(client: APIClient, rateLimiter: RateLimiter, apiKey: String) {
        self.client = client
        self.rateLimiter = rateLimiter
        self.apiKey = apiKey
    }

    func searchSymbols(_ query: String) async throws -> [Asset] {
        await rateLimiter.waitForToken(provider: provider)
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(base)?function=SYMBOL_SEARCH&keywords=\(encoded)&apikey=\(apiKey)")
        else { throw APIError.invalidURL }

        let response = try await client.fetch(AVSearchResponse.self, from: url)
        return response.bestMatches.compactMap(\.asAsset)
    }

    func fetchHistory(symbol: String, range: DateInterval, interval: BarInterval) async throws -> [PriceBar] {
        await rateLimiter.waitForToken(provider: provider)
        let function: String
        let outputSize = "full"

        switch interval {
        case .oneDay, .oneWeek, .oneMonth:
            function = "TIME_SERIES_DAILY_ADJUSTED"
        default:
            function = "TIME_SERIES_INTRADAY"
        }

        guard let url = URL(string: "\(base)?function=\(function)&symbol=\(symbol)&outputsize=\(outputSize)&apikey=\(apiKey)")
        else { throw APIError.invalidURL }

        let data = try await client.fetchData(from: url)
        return try parseAVHistory(data, range: range)
    }

    func fetchQuote(symbol: String) async throws -> Quote {
        await rateLimiter.waitForToken(provider: provider)
        guard let url = URL(string: "\(base)?function=GLOBAL_QUOTE&symbol=\(symbol)&apikey=\(apiKey)")
        else { throw APIError.invalidURL }

        let response = try await client.fetch(AVGlobalQuoteResponse.self, from: url)
        guard let q = response.globalQuote else { throw APIError.noData }
        return q.asQuote(symbol: symbol)
    }

    private func parseAVHistory(_ data: Data, range: DateInterval) throws -> [PriceBar] {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        // Key varies by function — find the time series key
        let tsKey = json.keys.first { $0.hasPrefix("Time Series") } ?? ""
        guard let series = json[tsKey] as? [String: [String: String]] else { throw APIError.noData }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "America/New_York")

        return series.compactMap { (dateStr, values) -> PriceBar? in
            guard let date = formatter.date(from: dateStr),
                  range.contains(date),
                  let o = Double(values["1. open"] ?? ""),
                  let h = Double(values["2. high"] ?? ""),
                  let l = Double(values["3. low"] ?? ""),
                  let c = Double(values["4. close"] ?? "")
            else { return nil }

            let adj = Double(values["5. adjusted close"] ?? "")
            let vol = Double(values["6. volume"] ?? "") ?? 0
            return PriceBar(date: date, open: o, high: h, low: l, close: c, volume: vol, adjustedClose: adj)
        }
    }
}

private struct AVSearchResponse: Decodable {
    let bestMatches: [AVMatch]
}

private struct AVMatch: Decodable {
    let symbol: String
    let name: String
    let type: String
    let region: String
    let currency: String

    enum CodingKeys: String, CodingKey {
        case symbol = "1. symbol"
        case name   = "2. name"
        case type   = "3. type"
        case region = "4. region"
        case currency = "8. currency"
    }

    var asAsset: Asset {
        Asset(id: symbol, name: name, exchange: region, kind: .stock, currency: currency, description: nil)
    }
}

private struct AVGlobalQuoteResponse: Decodable {
    let globalQuote: AVGlobalQuote?
    enum CodingKeys: String, CodingKey { case globalQuote = "Global Quote" }
}

private struct AVGlobalQuote: Decodable {
    let price: String
    let change: String
    let changePercent: String
    let volume: String

    enum CodingKeys: String, CodingKey {
        case price = "05. price"
        case change = "09. change"
        case changePercent = "10. change percent"
        case volume = "06. volume"
    }

    func asQuote(symbol: String) -> Quote {
        Quote(
            symbol: symbol,
            price: Double(price) ?? 0,
            change: Double(change) ?? 0,
            changePercent: Double(changePercent.replacingOccurrences(of: "%", with: "")) ?? 0,
            volume: Double(volume) ?? 0,
            marketCap: nil,
            timestamp: Date()
        )
    }
}
