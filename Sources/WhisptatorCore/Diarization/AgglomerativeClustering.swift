import Foundation

public enum EmbeddingMath {
    public static func l2Normalize(_ vector: [Double]) -> [Double] {
        var norm = 0.0
        for v in vector { norm += v * v }
        norm = norm.squareRoot()
        guard norm > 1e-9 else { return vector }
        return vector.map { $0 / norm }
    }

    /// Cosine distance in [0, 2]; assumes normalized inputs for speed.
    public static func cosineDistance(_ a: [Double], _ b: [Double]) -> Double {
        precondition(a.count == b.count)
        var dot = 0.0
        var na = 0.0
        var nb = 0.0
        for i in 0..<a.count {
            dot += a[i] * b[i]
            na += a[i] * a[i]
            nb += b[i] * b[i]
        }
        let denom = (na * nb).squareRoot()
        guard denom > 1e-12 else { return 1.0 }
        return 1.0 - dot / denom
    }

    public static func weightedMean(_ vectors: [[Double]], weights: [Double]) -> [Double] {
        guard let first = vectors.first, !vectors.isEmpty else { return [] }
        var mean = [Double](repeating: 0, count: first.count)
        var total = 0.0
        for (i, vector) in vectors.enumerated() {
            let weight = i < weights.count ? max(weights[i], 0) : 1
            for d in 0..<min(vector.count, mean.count) {
                mean[d] += vector[d] * weight
            }
            total += weight
        }
        guard total > 0 else { return mean }
        return mean.map { $0 / total }
    }
}

/// Weighted average-linkage agglomerative clustering on cosine distance.
///
/// Two stopping rules are applied in order, because either one alone fails on
/// real meetings:
///
///  * merge while the closest pair is within `distanceThreshold` — a hard cap on
///    how different two stretches of audio may be and still be one speaker;
///  * then, while more clusters than `maxClusters` remain, merge the closest
///    pair regardless of distance — the count a session claims should never
///    exceed what the room plausibly held.
///
/// Clusters supported by less than `minClusterWeight` (seconds of speech in the
/// diarizer's usage) are finally absorbed into their nearest neighbour: a
/// single mis-embedded window must not become a new person.
public enum AgglomerativeClustering {
    public struct Result: Sendable {
        public let labels: [Int]
        /// Cluster index per label id, in the order clusters were merged down to.
        public let centroids: [[Double]]
        public let clusterCount: Int

        /// Number of items assigned to each returned label id.
        public let sizes: [Int: Int]
        public let weights: [Int: Double]
    }

    public static func cluster(
        vectors: [[Double]],
        distanceThreshold: Double,
        weights: [Double]? = nil,
        maxClusters: Int? = nil,
        minClusterWeight: Double? = nil
    ) -> Result {
        let n = vectors.count
        guard n > 0 else { return Result(labels: [], centroids: [], clusterCount: 0, sizes: [:], weights: [:]) }
        let normalized = vectors.map { EmbeddingMath.l2Normalize($0) }
        guard n > 1 else {
            return Result(labels: [0], centroids: normalized, clusterCount: 1, sizes: [0: 1], weights: [0: weights?.first ?? 1])
        }

        let itemWeights = weights ?? Array(repeating: 1, count: n)
        var dist = [[Double]](repeating: [], count: n)
        for i in 0..<n {
            var row = [Double](repeating: 0, count: n)
            for j in 0..<i {
                let d = EmbeddingMath.cosineDistance(normalized[i], normalized[j])
                row[j] = d
                dist[j].append(d)
            }
            dist[i] = row
        }

        var memberships: [[Int]] = (0..<n).map { [$0] }
        var active = Array(repeating: true, count: n)
        var activeCount = n

        func merge(_ i: Int, _ j: Int) {
            memberships[i].append(contentsOf: memberships[j])
            memberships[j] = []
            active[j] = false
            activeCount -= 1
        }

        // Phase 1: merge everything closer than the threshold.
        while activeCount > 1 {
            guard let pair = closestPair(active: active, memberships: memberships, dist: dist, itemWeights: itemWeights) else { break }
            if pair.distance > distanceThreshold { break }
            merge(pair.i, pair.j)
        }

        // Phase 2: forced merges down to the cap, closest pair first.
        if let maxClusters, maxClusters > 0 {
            while activeCount > max(1, maxClusters) {
                guard let pair = closestPair(active: active, memberships: memberships, dist: dist, itemWeights: itemWeights) else { break }
                merge(pair.i, pair.j)
            }
        }

        // Phase 3: absorb thinly supported clusters.
        if let minClusterWeight, minClusterWeight > 0, activeCount > 1 {
            var changed = true
            while changed {
                changed = false
                var support: [(cluster: Int, weight: Double)] = []
                for i in 0..<n where active[i] {
                    let weight = memberships[i].reduce(0.0) { $0 + itemWeights[$1] }
                    support.append((i, weight))
                }
                guard let weakest = support.min(by: { $0.weight < $1.weight }), weakest.weight < minClusterWeight, support.count > 1 else { break }
                var bestOther = -1
                var bestDistance = Double.infinity
                for entry in support where entry.cluster != weakest.cluster {
                    let d = averageLinkageDistance(i: weakest.cluster, j: entry.cluster, dist: dist, memberships: memberships, itemWeights: itemWeights)
                    if d < bestDistance {
                        bestDistance = d
                        bestOther = entry.cluster
                    }
                }
                guard bestOther >= 0 else { break }
                // Surviving index is the well-supported cluster.
                merge(bestOther, weakest.cluster)
                changed = true
            }
        }

        var labels = [Int](repeating: -1, count: n)
        var sizes: [Int: Int] = [:]
        var clusterWeights: [Int: Double] = [:]
        var centroids: [[Double]] = []
        var clusterIndex = 0
        for i in 0..<n where active[i] {
            let members = memberships[i]
            for member in members { labels[member] = clusterIndex }
            sizes[clusterIndex] = members.count
            clusterWeights[clusterIndex] = members.reduce(0.0) { $0 + itemWeights[$1] }
            centroids.append(EmbeddingMath.l2Normalize(
                EmbeddingMath.weightedMean(members.map { normalized[$0] }, weights: members.map { itemWeights[$0] })
            ))
            clusterIndex += 1
        }
        return Result(labels: labels, centroids: centroids, clusterCount: clusterIndex, sizes: sizes, weights: clusterWeights)
    }

    /// Convenience for callers that only need labels.
    public static func cluster(vectors: [[Double]], distanceThreshold: Double) -> [Int] {
        cluster(vectors: vectors, distanceThreshold: distanceThreshold, weights: nil, maxClusters: nil, minClusterWeight: nil).labels
    }

    private struct Pair { let i: Int; let j: Int; let distance: Double }

    private static func closestPair(
        active: [Bool],
        memberships: [[Int]],
        dist: [[Double]],
        itemWeights: [Double]
    ) -> Pair? {
        let n = active.count
        var best: Pair?
        for i in 0..<n where active[i] {
            for j in 0..<i where active[j] {
                let d = averageLinkageDistance(i: i, j: j, dist: dist, memberships: memberships, itemWeights: itemWeights)
                if d < (best?.distance ?? .infinity) {
                    best = Pair(i: i, j: j, distance: d)
                }
            }
        }
        return best
    }

    private static func averageLinkageDistance(
        i: Int,
        j: Int,
        dist: [[Double]],
        memberships: [[Int]],
        itemWeights: [Double]
    ) -> Double {
        let groupI = memberships[i]
        let groupJ = memberships[j]
        guard !groupI.isEmpty, !groupJ.isEmpty else { return .infinity }
        var sum = 0.0
        var weight = 0.0
        for a in groupI {
            let wa = itemWeights[a]
            for b in groupJ {
                let lo = max(a, b)
                let hi = min(a, b)
                let wb = itemWeights[b]
                sum += dist[lo][hi] * wa * wb
                weight += wa * wb
            }
        }
        guard weight > 0 else { return .infinity }
        return sum / weight
    }
}
