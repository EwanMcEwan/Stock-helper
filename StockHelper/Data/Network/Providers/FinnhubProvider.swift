import Foundation

/// Finnhub fallback provider.
/// Free tier: 60 calls/minute. Supports US stocks and some European symbols.
final class FinnhubProvider: MarketDataProvider {
    let name = "Finnhub"
    private let client: APIClient
    private let rateLimiter: RateLimiter
    private let apiKey: String
    private let base = "https://finnhub.io/api/v1"
    private let provider = "finnhub"

    init(client: APIClient, rateLimiter: RateLimiter, apiKey: String) {
        self.client = client
        self.rateLimiter = rateLimiter
        self.apiKey = apiKey
    }

    func searchSymbols(_ query: String) async throws -> [Asset] {
        await rateLimiter.waitForToken(provider: provider)
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(base)/search?q=\(encoded)&token=\(apiKey)")
        else { throw APIError.invalidURL }

        let response = try await client.fetch(FinnhubSearchResponse.self, from: url)
        return response.result.map { r in
            Asset(id: r.symbol, name: r.description, exchange: r.type, kind: .stock, currency: "USD", description: nil)
        }
    }

    func fetchHistory(symbol: String, range: DateInterval, interval: BarInterval) async throws -> [PriceBar] {
        await rateLimiter.waitForToken(provider: provider)

        let resolution = finnhubResolution(for: interval)
        let from = Int(range.start.timeIntervalSince1970)
        let to   = Int(range.end.timeIntervalSince1970)

        guard let url = URL(string: "\(base)/stock/candle?symbol=\(symbol)&resolution=\(resolution)&from=\(from)&to=\(to)&token=\(apiKey)")
        else { throw APIError.invalidURL }

        let response = try await client.fetch(FinnhubCandleResponse.self, from: url)
        guard response.s == "ok" else { throw APIError.noData }

        let count = response.t?.count ?? 0
        var bars: [PriceBar] = []
        for i in 0..<count {
            guard
                let t = response.t?[i],
                let o = response.o?[i],
                let h = response.h?[i],
                let l = response.l?[i],
                let c = response.c?[i]
            else { continue }

            let date = Date(timeIntervalSince1970: TimeInterval(t))
            let vol  = response.v?[i] ?? 0
            bars.append(PriceBar(date: date, open: o, high: h, low: l, close: c, volume: vol))
        }
        return bars
    }

    func fetchQuote(symbol: String) async throws -> Quote {
        await rateLimiter.waitForToken(provider: provider)
        guard let url = URL(string: "\(base)/quote?symbol=\(symbol)&token=\(apiKey)")
        else { throw APIError.invalidURL }

        let response = try await client.fetch(FinnhubQuoteResponse.self, from: url)
        let price = response.c
        let prev  = response.pc
        let change = price - prev
        let changePercent = prev != 0 ? (change / prev) * 100 : 0

        return Quote(
            symbol: symbol,
            price: price,
            change: change,
            changePercent: changePercent,
            volume: 0,
            marketCap: nil,
            timestamp: Date(timeIntervalSince1970: TimeInterval(response.t))
        )
    }

    private func finnhubResolution(for interval: BarInterval) -> String {
        switch interval {
        case .oneMinute: return "1"
        case .fiveMinutes: return "5"
        case .fifteenMinutes: return "15"
        case .oneHour: return "60"
        case .oneDay: return "D"
        case .oneWeek: return "W"
        case .oneMonth: return "M"
        }
    }
}

private struct FinnhubSearchResponse: Decodable {
    let result: [FinnhubSearchResult]
}

private struct FinnhubSearchResult: Decodable {
    let symbol: String
    let description: String
    let type: String
}

private struct FinnhubCandleResponse: Decodable {
    let s: String?
    let t: [Int]?
    let o: [Double]?
    let h: [Double]?
    let l: [Double]?
    let c: [Double]?
    let v: [Double]?
}

private struct FinnhubQuoteResponse: Decodable {
    let c: Double   // current price
    let pc: Double  // previous close
    let t: Int      // timestamp
}
