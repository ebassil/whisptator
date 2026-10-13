import Foundation

/// Collapses periodic word loops out of a transcript line.
///
/// A recognizer fed audio it cannot parse (two speakers at once, a stretch of
/// music, a segment cut mid-word) answers with the same short phrase over and
/// over — real example from a meeting transcript: `a medium, a medium, a medium`
/// repeated forty times until the segment ran out. That is a decoding artifact,
/// not speech, and it drowns whatever the line was trying to say.
///
/// Detects a repeating cycle of 1...6 tokens that runs at least `minCycles`
/// times, keeps a single occurrence, and drops the remainder. Genuine emphasis
/// ("very, very good") survives because it is far below the cycle count.
public enum RepetitionCollapser {
    public static let minCycles = 4

    public static func collapse(_ text: String) -> String {
        let words = text.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard words.count >= minCycles else { return text }

        var result: [String] = []
        var index = 0
        while index < words.count {
            if let loop = loopAt(words, from: index) {
                result.append(contentsOf: Array(words[index..<(index + loop.period)]))
                index += loop.period * loop.cycles
            } else {
                result.append(words[index])
                index += 1
            }
        }
        var cleaned = result.joined(separator: " ")
        // A collapsed loop can leave a doubled trailing punctuation mark.
        while cleaned.hasSuffix(",,") { cleaned.removeLast() }
        while cleaned.hasSuffix("..") && !cleaned.hasSuffix("...") { cleaned.removeLast() }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Length (period, repetitions) of a token cycle starting at `start`, when
    /// the period repeats at least `minCycles` times. A period only matches when
    /// it also looks like a stutter: an exact adjacent repeat of a short span.
    private static func loopAt(_ words: [String], from start: Int) -> (period: Int, cycles: Int)? {
        let maxPeriod = min(6, (words.count - start) / minCycles)
        guard maxPeriod >= 1 else { return nil }
        for period in 1...maxPeriod {
            var cycles = 1
            var i = start + period
            while i + period <= words.count, matches(words, a: start, b: i, length: period) {
                cycles += 1
                i += period
            }
            if cycles >= minCycles { return (period, cycles) }
        }
        return nil
    }

    private static func matches(_ words: [String], a: Int, b: Int, length: Int) -> Bool {
        for offset in 0..<length where words[a + offset] != words[b + offset] {
            return false
        }
        return true
    }
}
