import Foundation

/// Token-bucket rate limiter. Thread-safe via an actor.
actor RateLimiter {
    private var buckets: [String: TokenBucket] = [:]

    func configure(provider: String, requestsPerSecond: Double, burst: Int) {
        buckets[provider] = TokenBucket(rate: requestsPerSecond, burst: burst)
    }

    /// Wait until a token is available for the given provider.
    func waitForToken(provider: String) async {
        if buckets[provider] == nil {
            buckets[provider] = TokenBucket(rate: 1.0, burst: 5)
        }
        await buckets[provider]!.consumeToken()
    }

    func isRateLimited(provider: String) -> Bool {
        buckets[provider]?.tokens == 0
    }
}

actor TokenBucket {
    private let rate: Double    // tokens per second
    private let burst: Int
    private(set) var tokens: Double
    private var lastRefill: Date

    init(rate: Double, burst: Int) {
        self.rate = rate
        self.burst = burst
        self.tokens = Double(burst)
        self.lastRefill = Date()
    }

    func consumeToken() async {
        refill()
        if tokens >= 1.0 {
            tokens -= 1.0
            return
        }
        // Calculate wait time to get one token
        let waitSeconds = (1.0 - tokens) / rate
        try? await Task.sleep(nanoseconds: UInt64(waitSeconds * 1_000_000_000))
        refill()
        tokens = max(tokens - 1.0, 0)
    }

    private func refill() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastRefill)
        tokens = min(Double(burst), tokens + elapsed * rate)
        lastRefill = now
    }
}
