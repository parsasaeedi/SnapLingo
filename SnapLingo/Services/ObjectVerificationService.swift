import Foundation

// Lightweight classification value used by the verifier
struct Classification: Equatable {
    let label: String
    let confidence: Double
}

struct VerificationOptions {
    var topK: Int = 10
    // Confidence is ignored for exact matches; used as a gate for fuzzy only
    var minConfidence: Double = 0.0
    var enableFuzzy: Bool = true
    var jaccardThreshold: Double = 0.85
    var maxEditDistance: Int = 2
}

struct VerificationResult {
    let isMatch: Bool
    let matchedModelLabel: String?
    let matchedPrediction: Classification?
    let reason: String
}

protocol ObjectVerifying {
    func verify(modelLabels: [String], predictions: [Classification], options: VerificationOptions) -> VerificationResult
}

final class ObjectVerificationService: ObjectVerifying {
    func verify(modelLabels: [String], predictions: [Classification], options: VerificationOptions = .init()) -> VerificationResult {
        // Expand aliases: normalize and also split any "/" leftovers into additional aliases
        let aliases: [String] = modelLabels
            .flatMap { $0.split(on: "/") }
            .map { $0.normalized() }
            .filter { !$0.isEmpty }

        guard !aliases.isEmpty else {
            return .init(isMatch: false, matchedModelLabel: nil, matchedPrediction: nil, reason: "no_aliases")
        }

        // Expand prediction synonyms (commas and slashes) and normalize
        let preds: [Classification] = predictions
            .prefix(options.topK)
            .flatMap { p in
                p.label
                    .splitMulti([",", "/"]) // split into synonyms
                    .map { Classification(label: $0.normalized(), confidence: p.confidence) }
            }

        // 1) exact alias match
        for p in preds {
            if let hit = aliases.first(where: { $0 == p.label }) {
                return .init(isMatch: true, matchedModelLabel: hit, matchedPrediction: p, reason: "exact")
            }
        }

        // 2) light fuzzy matching (token Jaccard + edit distance)
        if options.enableFuzzy {
            for p in preds where p.confidence >= options.minConfidence {
                let pTokens = p.label.tokens()
                for a in aliases {
                    if a.tokens().jaccard(with: pTokens) >= options.jaccardThreshold || a.editDistance(to: p.label) <= options.maxEditDistance {
                        return .init(isMatch: true, matchedModelLabel: a, matchedPrediction: p, reason: "fuzzy")
                    }
                }
            }
        }

        return .init(isMatch: false, matchedModelLabel: nil, matchedPrediction: nil, reason: "no_match")
    }

    // Optional helper that logs the outcome for quick diagnostics
    func verifyAndLog(modelLabels: [String], predictions: [Classification], options: VerificationOptions = .init()) -> VerificationResult {
        let result = verify(modelLabels: modelLabels, predictions: predictions, options: options)
        let labelList = modelLabels.joined(separator: ", ")
        if result.isMatch, let pred = result.matchedPrediction, let hit = result.matchedModelLabel {
            print("[Verify] MATCH (\(result.reason)): \(hit) <= \(pred.label) @ \(String(format: "%.2f", pred.confidence)) | aliases=[\(labelList)]")
        } else {
            print("[Verify] NO MATCH: aliases=[\(labelList)]")
        }
        return result
    }
}

// MARK: - Convenience mapping from ImageClassificationService.Result
extension Array where Element == ImageClassificationService.Result {
    func asClassifications() -> [Classification] {
        map { Classification(label: $0.identifier, confidence: Double($0.confidence)) }
    }
}

// MARK: - String helpers
private extension String {
    func normalized() -> String {
        let lowered = self.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let cleaned = lowered.replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
        return cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func tokens() -> Set<String> {
        Set(self.normalized().split(separator: " ").map(String.init))
    }

    func editDistance(to other: String) -> Int {
        let a = Array(self), b = Array(other)
        var dp = Array(0...b.count)
        for i in 1...a.count {
            var prev = dp[0]; dp[0] = i
            for j in 1...b.count {
                let cur = dp[j]
                if a[i-1] == b[j-1] {
                    dp[j] = prev
                } else {
                    let m = Swift.min(prev, Swift.min(dp[j], dp[j-1]))
                    dp[j] = m + 1
                }
                prev = cur
            }
        }
        return dp[b.count]
    }

    func split(on delimiter: Character) -> [String] {
        self.split(separator: delimiter).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    func splitMulti(_ delimiters: [Character]) -> [String] {
        var parts: [String] = [self]
        for d in delimiters {
            parts = parts.flatMap { $0.split(on: d) }
        }
        return parts
    }
}

private extension Set where Element == String {
    func jaccard(with other: Set<String>) -> Double {
        if isEmpty && other.isEmpty { return 1.0 }
        let inter = self.intersection(other).count
        let uni = self.union(other).count
        if uni == 0 { return 0.0 }
        return Double(inter) / Double(uni)
    }
}
